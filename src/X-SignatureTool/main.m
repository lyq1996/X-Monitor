//
//  main.m
//  X-SignatureTool
//
//  Created by lyq1996 on 2024/3/23.
//

#import <Foundation/Foundation.h>
#import "SignatureVerifier.h"
#import <mach-o/loader.h>
#import <mach-o/fat.h>
#import <arpa/inet.h>

static const char *version = "1.0.0";
static const size_t kSignatureSize = 256;

static void print_help(char * const *argv, FILE *file) {
    fprintf(file, "Usage: \n\t%s [-hv] <-d | -e> <-k key_file> <target mach-o file>\n", argv[0]);
    fprintf(file, "\nOptions:\n");
    fprintf(file, "\t-d\tVerify (check) signature using public key\n");
    fprintf(file, "\t-e\tEmbed (write) signature using private key\n");
    fprintf(file, "\t-k\tPath to PEM key file (public key for -d, private key for -e)\n");
    fprintf(file, "\t-h\tShow this help\n");
    fprintf(file, "\t-v\tShow version\n");
}

static void print_hash(NSData *hash) {
    for (NSUInteger i = 0; i < hash.length; i++) {
        fprintf(stdout, "%02x", ((const uint8_t *)hash.bytes)[i]);
    }
    fprintf(stdout, "\n");
}

#pragma mark - Fat Binary

static BOOL is_fat_binary(NSData *data) {
    if (data.length < sizeof(struct fat_header)) {
        return NO;
    }
    uint32_t magic = *(uint32_t *)data.bytes;
    return (magic == FAT_MAGIC || magic == FAT_CIGAM || magic == FAT_MAGIC_64 || magic == FAT_CIGAM_64);
}

static NSArray *get_fat_arch_offsets(NSData *data) {
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    uint32_t magic = *(uint32_t *)bytes;
    BOOL needsSwap = (magic == FAT_CIGAM || magic == FAT_CIGAM_64);
    BOOL is64 = (magic == FAT_MAGIC_64 || magic == FAT_CIGAM_64);

    struct fat_header header;
    memcpy(&header, bytes, sizeof(header));
    uint32_t nfat_arch = needsSwap ? OSSwapBigToHostInt32(header.nfat_arch) : header.nfat_arch;

    NSMutableArray *offsets = [NSMutableArray arrayWithCapacity:nfat_arch];
    size_t archEntrySize = is64 ? sizeof(struct fat_arch_64) : sizeof(struct fat_arch);
    const uint8_t *archPtr = bytes + sizeof(struct fat_header);

    for (uint32_t i = 0; i < nfat_arch; i++) {
        if (is64) {
            struct fat_arch_64 arch;
            memcpy(&arch, archPtr, sizeof(arch));
            uint64_t off = needsSwap ? OSSwapBigToHostInt64(arch.offset) : arch.offset;
            [offsets addObject:@((uint32_t)off)];
        } else {
            struct fat_arch arch;
            memcpy(&arch, archPtr, sizeof(arch));
            uint32_t off = needsSwap ? OSSwapBigToHostInt32(arch.offset) : arch.offset;
            [offsets addObject:@(off)];
        }
        archPtr += archEntrySize;
    }

    return offsets;
}

#pragma mark - Section Write

static int write_signature_to_section(NSMutableData *machoData, uint32_t archOffset, NSData *signature) {
    uint32_t sectionOffset = 0;
    uint32_t sectionSize = 0;

    if ([SignatureVerifier findCustomSignatureSection:machoData archOffset:archOffset sectionOffset:&sectionOffset sectionSize:&sectionSize] != 0) {
        return -1;
    }

    if (sectionSize < kSignatureSize) {
        fprintf(stderr, "Error: Signature section too small (%u < %zu)\n", sectionSize, kSignatureSize);
        return -1;
    }

    if (signature.length > kSignatureSize) {
        fprintf(stderr, "Error: Signature too large (%lu > %zu)\n", (unsigned long)signature.length, kSignatureSize);
        return -1;
    }

    uint8_t *dst = (uint8_t *)machoData.mutableBytes + archOffset + sectionOffset;
    memset(dst, 0, kSignatureSize);
    memcpy(dst, signature.bytes, signature.length);

    return 0;
}

#pragma mark - Embed / Verify per arch

static int process_single_arch_embed(NSMutableData *machoData, uint32_t archOffset, SecKeyRef privKey) {
    NSData *hash = [SignatureVerifier calculateTextSegmentHash:machoData archOffset:archOffset];
    if (!hash) {
        return -1;
    }

    fprintf(stdout, "  __TEXT segment hash: ");
    print_hash(hash);

    NSData *signature = [SignatureVerifier signHash:hash privateKeyRef:privKey];
    if (!signature) {
        fprintf(stderr, "  Error: RSA sign failed\n");
        return -1;
    }

    fprintf(stdout, "  RSA signature length: %lu bytes\n", (unsigned long)signature.length);

    return write_signature_to_section(machoData, archOffset, signature);
}

static int process_single_arch_verify(NSData *machoData, uint32_t archOffset, SecKeyRef pubKey) {
    NSData *hash = [SignatureVerifier calculateTextSegmentHash:machoData archOffset:archOffset];
    if (!hash) {
        return -1;
    }

    fprintf(stdout, "  __TEXT segment hash: ");
    print_hash(hash);

    NSData *signature = [SignatureVerifier readSignatureFromMachO:machoData archOffset:archOffset];
    if (!signature) {
        fprintf(stderr, "  Signature section is empty or not found\n");
        return -1;
    }

    fprintf(stdout, "  Signature length: %zu bytes\n", signature.length);

    if ([SignatureVerifier verifyHash:hash withSignature:signature publicKeyRef:pubKey]) {
        fprintf(stdout, "  Signature VALID\n");
        return 0;
    } else {
        fprintf(stderr, "  Signature INVALID\n");
        return -1;
    }
}

#pragma mark - Main Operations

static void write_signature(const char *macho, const char *keyPath) {
    NSString *nsKeyPath = [NSString stringWithUTF8String:keyPath];
    SecKeyRef privKey = [SignatureVerifier createPrivateKeyFromPEMFile:nsKeyPath];
    if (!privKey) {
        fprintf(stderr, "Error: Cannot load private key from %s\n", keyPath);
        exit(EXIT_FAILURE);
    }

    fprintf(stdout, "Step 1: Calculating hash and signing...\n");

    NSMutableData *data = [[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:macho]] mutableCopy];
    if (!data) {
        fprintf(stderr, "Error: Cannot read file %s\n", macho);
        CFRelease(privKey);
        exit(EXIT_FAILURE);
    }

    if (is_fat_binary(data)) {
        NSArray *offsets = get_fat_arch_offsets(data);
        fprintf(stdout, "Fat binary with %lu architectures\n", (unsigned long)offsets.count);

        for (NSUInteger i = 0; i < offsets.count; i++) {
            fprintf(stdout, "Architecture %lu (offset %u):\n", (unsigned long)i, [offsets[i] unsignedIntValue]);
            if (process_single_arch_embed(data, [offsets[i] unsignedIntValue], privKey) != 0) {
                fprintf(stderr, "Error: Failed to sign architecture %lu\n", (unsigned long)i);
                CFRelease(privKey);
                exit(EXIT_FAILURE);
            }
        }
    } else {
        fprintf(stdout, "Single architecture Mach-O\n");
        if (process_single_arch_embed(data, 0, privKey) != 0) {
            CFRelease(privKey);
            exit(EXIT_FAILURE);
        }
    }

    CFRelease(privKey);

    fprintf(stdout, "Step 2: Writing signed Mach-O...\n");
    if (![data writeToFile:[NSString stringWithUTF8String:macho] atomically:YES]) {
        fprintf(stderr, "Error: Cannot write file %s\n", macho);
        exit(EXIT_FAILURE);
    }

    fprintf(stdout, "Signature embedded successfully\n");
}

static void check_signature(const char *macho, const char *keyPath) {
    NSString *nsKeyPath = [NSString stringWithUTF8String:keyPath];
    SecKeyRef pubKey = [SignatureVerifier createPublicKeyFromPEMFile:nsKeyPath];
    if (!pubKey) {
        fprintf(stderr, "Error: Cannot load public key from %s\n", keyPath);
        exit(EXIT_FAILURE);
    }

    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:macho]];
    if (!data) {
        fprintf(stderr, "Error: Cannot read file %s\n", macho);
        CFRelease(pubKey);
        exit(EXIT_FAILURE);
    }

    if (is_fat_binary(data)) {
        NSArray *offsets = get_fat_arch_offsets(data);
        fprintf(stdout, "Fat binary with %lu architectures\n", (unsigned long)offsets.count);

        int failCount = 0;
        for (NSUInteger i = 0; i < offsets.count; i++) {
            fprintf(stdout, "Architecture %lu (offset %u):\n", (unsigned long)i, [offsets[i] unsignedIntValue]);
            if (process_single_arch_verify(data, [offsets[i] unsignedIntValue], pubKey) != 0) {
                failCount++;
            }
        }
        CFRelease(pubKey);

        if (failCount > 0) {
            exit(EXIT_FAILURE);
        }
    } else {
        fprintf(stdout, "Single architecture Mach-O\n");
        if (process_single_arch_verify(data, 0, pubKey) != 0) {
            CFRelease(pubKey);
            exit(EXIT_FAILURE);
        }
        CFRelease(pubKey);
    }
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        int opt;
        int d_flag = 0;
        int e_flag = 0;
        const char *key = NULL;
        const char *macho = NULL;

        while ((opt = getopt(argc, argv, "hvdek:")) != -1) {
            switch (opt) {
                case 'd': d_flag = 1; break;
                case 'e': e_flag = 1; break;
                case 'k': key = optarg; break;
                case 'h': print_help(argv, stdout); exit(EXIT_SUCCESS);
                case 'v': printf("%s version: %s\n", argv[0], version); exit(EXIT_SUCCESS);
                case '?': print_help(argv, stderr); exit(EXIT_FAILURE);
                default:  print_help(argv, stderr); exit(EXIT_FAILURE);
            }
        }

        if ((d_flag && e_flag) || (!d_flag && !e_flag)) {
            fprintf(stderr, "-d or -e option must be specified, but not both.\n");
            print_help(argv, stderr);
            exit(EXIT_FAILURE);
        }

        if (key == NULL) {
            fprintf(stderr, "-k key must be specified.\n");
            print_help(argv, stderr);
            exit(EXIT_FAILURE);
        }

        for (int i = optind; i < argc; i++) {
            macho = argv[i];
        }

        if (macho == NULL) {
            fprintf(stderr, "Target Mach-O file must be specified.\n");
            print_help(argv, stderr);
            exit(EXIT_FAILURE);
        }

        printf("Target Mach-O file: %s\n", macho);

        if (d_flag) {
            check_signature(macho, key);
        } else {
            write_signature(macho, key);
        }
    }

    return 0;
}
