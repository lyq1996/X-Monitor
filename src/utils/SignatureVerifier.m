//
//  SignatureVerifier.m
//  X-Service
//
//  Created by lyq1996 on 2024/3/23.
//

#import "SignatureVerifier.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import <mach-o/loader.h>
#import <mach-o/fat.h>
#import <arpa/inet.h>

#ifdef SIGNATURE_VERIFIER_NO_LOG
#define SVLogError(fmt, ...) do {} while(0)
#define SVLogInfo(fmt, ...) do {} while(0)
#else
#import <CocoaLumberjack/CocoaLumberjack.h>
extern DDLogLevel ddLogLevel;
#define SVLogError DDLogError
#define SVLogInfo DDLogInfo
#endif

static const char *kCustomSegmentName = "__X_CUSTOM";
static const char *kCustomSectionName = "__SIGNATURE";
static const size_t kSignatureSize = 256;

#include "embedded_public_key.h"

@implementation SignatureVerifier

+ (NSData *)calculateTextSegmentHash:(NSData *)machoData archOffset:(uint32_t)offset {
    if (offset + sizeof(uint32_t) > machoData.length) {
        return nil;
    }

    const uint8_t *bytes = (const uint8_t *)machoData.bytes + offset;
    uint32_t magic = *(uint32_t *)bytes;

    BOOL is64 = (magic == MH_MAGIC_64 || magic == MH_CIGAM_64);
    uint32_t ncmds;
    const uint8_t *cmdPtr;

    if (is64) {
        if (offset + sizeof(struct mach_header_64) > machoData.length) {
            return nil;
        }
        struct mach_header_64 *header = (struct mach_header_64 *)bytes;
        ncmds = header->ncmds;
        cmdPtr = bytes + sizeof(struct mach_header_64);
    } else {
        if (offset + sizeof(struct mach_header) > machoData.length) {
            return nil;
        }
        struct mach_header *header = (struct mach_header *)bytes;
        ncmds = header->ncmds;
        cmdPtr = bytes + sizeof(struct mach_header);
    }

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);

    for (uint32_t i = 0; i < ncmds; i++) {
        if ((size_t)(cmdPtr - bytes) + sizeof(uint32_t) * 2 > machoData.length - offset) {
            return nil;
        }

        if (is64) {
            struct segment_command_64 *seg = (struct segment_command_64 *)cmdPtr;
            if (seg->cmd == LC_SEGMENT_64 && strncmp(seg->segname, SEG_TEXT, 16) == 0) {
                uint32_t nsects = seg->nsects;
                const uint8_t *sectPtr = cmdPtr + sizeof(struct segment_command_64);

                for (uint32_t j = 0; j < nsects; j++) {
                    if ((size_t)(sectPtr - bytes) + sizeof(struct section_64) > machoData.length - offset) {
                        break;
                    }
                    struct section_64 *sect = (struct section_64 *)sectPtr;
                    if (strncmp(sect->segname, kCustomSegmentName, 16) == 0 &&
                        strncmp(sect->sectname, kCustomSectionName, 16) == 0) {
                        sectPtr += sizeof(struct section_64);
                        continue;
                    }

                    if (sect->offset == 0 || sect->size == 0) {
                        sectPtr += sizeof(struct section_64);
                        continue;
                    }

                    uint64_t sectFileOff = sect->offset;
                    uint64_t sectSize = sect->size;
                    if (offset + sectFileOff + sectSize <= machoData.length) {
                        CC_SHA256_Update(&ctx, (const uint8_t *)machoData.bytes + offset + sectFileOff, (CC_LONG)sectSize);
                    }
                    sectPtr += sizeof(struct section_64);
                }
            }
            cmdPtr += seg->cmdsize;
        } else {
            struct segment_command *seg = (struct segment_command *)cmdPtr;
            if (seg->cmd == LC_SEGMENT && strncmp(seg->segname, SEG_TEXT, 16) == 0) {
                uint32_t nsects = seg->nsects;
                const uint8_t *sectPtr = cmdPtr + sizeof(struct segment_command);

                for (uint32_t j = 0; j < nsects; j++) {
                    if ((size_t)(sectPtr - bytes) + sizeof(struct section) > machoData.length - offset) {
                        break;
                    }
                    struct section *sect = (struct section *)sectPtr;
                    if (strncmp(sect->segname, kCustomSegmentName, 16) == 0 &&
                        strncmp(sect->sectname, kCustomSectionName, 16) == 0) {
                        sectPtr += sizeof(struct section);
                        continue;
                    }

                    if (sect->offset == 0 || sect->size == 0) {
                        sectPtr += sizeof(struct section);
                        continue;
                    }

                    uint32_t sectFileOff = sect->offset;
                    uint32_t sectSize = sect->size;
                    if (offset + sectFileOff + sectSize <= machoData.length) {
                        CC_SHA256_Update(&ctx, (const uint8_t *)machoData.bytes + offset + sectFileOff, sectSize);
                    }
                    sectPtr += sizeof(struct section);
                }
            }
            cmdPtr += seg->cmdsize;
        }
    }

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &ctx);
    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

+ (int)findCustomSignatureSection:(NSData *)machoData
                       archOffset:(uint32_t)offset
                    sectionOffset:(uint32_t *)outOffset
                     sectionSize:(uint32_t *)outSize {
    const uint8_t *bytes = (const uint8_t *)machoData.bytes + offset;
    uint32_t magic = *(uint32_t *)bytes;

    BOOL is64 = (magic == MH_MAGIC_64 || magic == MH_CIGAM_64);
    uint32_t ncmds;
    const uint8_t *cmdPtr;

    if (is64) {
        struct mach_header_64 *header = (struct mach_header_64 *)bytes;
        ncmds = header->ncmds;
        cmdPtr = bytes + sizeof(struct mach_header_64);
    } else {
        struct mach_header *header = (struct mach_header *)bytes;
        ncmds = header->ncmds;
        cmdPtr = bytes + sizeof(struct mach_header);
    }

    for (uint32_t i = 0; i < ncmds; i++) {
        if (is64) {
            struct segment_command_64 *seg = (struct segment_command_64 *)cmdPtr;
            if (seg->cmd == LC_SEGMENT_64 && strncmp(seg->segname, kCustomSegmentName, 16) == 0) {
                uint32_t nsects = seg->nsects;
                const uint8_t *sectPtr = cmdPtr + sizeof(struct segment_command_64);
                for (uint32_t j = 0; j < nsects; j++) {
                    struct section_64 *sect = (struct section_64 *)sectPtr;
                    if (strncmp(sect->sectname, kCustomSectionName, 16) == 0) {
                        *outOffset = sect->offset;
                        *outSize = (uint32_t)sect->size;
                        return 0;
                    }
                    sectPtr += sizeof(struct section_64);
                }
            }
            cmdPtr += seg->cmdsize;
        } else {
            struct segment_command *seg = (struct segment_command *)cmdPtr;
            if (seg->cmd == LC_SEGMENT && strncmp(seg->segname, kCustomSegmentName, 16) == 0) {
                uint32_t nsects = seg->nsects;
                const uint8_t *sectPtr = cmdPtr + sizeof(struct segment_command);
                for (uint32_t j = 0; j < nsects; j++) {
                    struct section *sect = (struct section *)sectPtr;
                    if (strncmp(sect->sectname, kCustomSectionName, 16) == 0) {
                        *outOffset = sect->offset;
                        *outSize = sect->size;
                        return 0;
                    }
                    sectPtr += sizeof(struct section);
                }
            }
            cmdPtr += seg->cmdsize;
        }
    }

    return -1;
}

+ (NSData *)readSignatureFromMachO:(NSData *)machoData archOffset:(uint32_t)offset {
    uint32_t sectionOffset = 0;
    uint32_t sectionSize = 0;
    if ([self findCustomSignatureSection:machoData archOffset:offset sectionOffset:&sectionOffset sectionSize:&sectionSize] != 0) {
        return nil;
    }

    if (sectionSize < kSignatureSize) {
        return nil;
    }

    if (offset + sectionOffset + kSignatureSize > machoData.length) {
        return nil;
    }

    NSData *signatureData = [machoData subdataWithRange:NSMakeRange(offset + sectionOffset, kSignatureSize)];

    size_t actualSigLen = kSignatureSize;
    const uint8_t *sigBytes = (const uint8_t *)signatureData.bytes;
    while (actualSigLen > 0 && sigBytes[actualSigLen - 1] == 0) {
        actualSigLen--;
    }
    if (actualSigLen == 0) {
        return nil;
    }

    return [NSData dataWithBytes:sigBytes length:actualSigLen];
}

#pragma mark - Key Loading

+ (NSData *)derDataFromPEM:(NSString *)pemStr header:(NSString *)header footer:(NSString *)footer {
    NSString *b64 = [pemStr stringByReplacingOccurrencesOfString:header withString:@""];
    b64 = [b64 stringByReplacingOccurrencesOfString:footer withString:@""];
    b64 = [b64 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    b64 = [b64 stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    b64 = [b64 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [[NSData alloc] initWithBase64EncodedString:b64 options:0];
}

+ (SecKeyRef)createPublicKeyFromPEMFile:(NSString *)pemPath {
    NSString *pem = [NSString stringWithContentsOfFile:pemPath encoding:NSUTF8StringEncoding error:nil];
    if (!pem) return nil;

    NSData *derData = [self derDataFromPEM:pem
                                    header:@"-----BEGIN PUBLIC KEY-----"
                                    footer:@"-----END PUBLIC KEY-----"];
    if (!derData) return nil;

    NSDictionary *attrs = @{
        (id)kSecAttrKeyType:       (id)kSecAttrKeyTypeRSA,
        (id)kSecAttrKeyClass:      (id)kSecAttrKeyClassPublic,
        (id)kSecAttrKeySizeInBits: @2048,
    };

    CFErrorRef error = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)derData,
                                         (__bridge CFDictionaryRef)attrs,
                                         &error);
    if (error) {
        SVLogError(@"SignatureVerifier: SecKeyCreateWithData (public) error: %@", (__bridge NSError *)error);
        CFRelease(error);
    }
    return key;
}

+ (BOOL)parseASN1Length:(const uint8_t **)ptr end:(const uint8_t *)end outLen:(NSUInteger *)outLen {
    if (*ptr >= end) return NO;
    uint8_t first = *(*ptr)++;
    if (!(first & 0x80)) {
        *outLen = first;
        return YES;
    }
    int numBytes = first & 0x7f;
    if (numBytes > 4 || *ptr + numBytes > end) return NO;
    NSUInteger len = 0;
    for (int i = 0; i < numBytes; i++) {
        len = (len << 8) | *(*ptr)++;
    }
    *outLen = len;
    return YES;
}

+ (BOOL)skipASN1Element:(const uint8_t **)ptr end:(const uint8_t *)end {
    if (*ptr >= end) return NO;
    (*ptr)++;
    NSUInteger len;
    if (![self parseASN1Length:ptr end:end outLen:&len]) return NO;
    *ptr += len;
    return (*ptr <= end);
}

+ (NSData *)stripPKCS8Wrapper:(NSData *)pkcs8der {
    const uint8_t *ptr = (const uint8_t *)pkcs8der.bytes;
    const uint8_t *end = ptr + pkcs8der.length;

    if (*ptr++ != 0x30) return nil;
    NSUInteger outerLen;
    if (![self parseASN1Length:&ptr end:end outLen:&outerLen]) return nil;
    if (![self skipASN1Element:&ptr end:end]) return nil;
    if (![self skipASN1Element:&ptr end:end]) return nil;
    if (ptr >= end || *ptr++ != 0x04) return nil;
    NSUInteger octetLen;
    if (![self parseASN1Length:&ptr end:end outLen:&octetLen]) return nil;
    if (ptr + octetLen > end) return nil;

    return [NSData dataWithBytes:ptr length:octetLen];
}

+ (SecKeyRef)createPrivateKeyFromPEMFile:(NSString *)pemPath {
    NSString *pem = [NSString stringWithContentsOfFile:pemPath encoding:NSUTF8StringEncoding error:nil];
    if (!pem) return nil;

    NSData *derData = [self derDataFromPEM:pem
                                    header:@"-----BEGIN RSA PRIVATE KEY-----"
                                    footer:@"-----END RSA PRIVATE KEY-----"];
    if (!derData) {
        derData = [self derDataFromPEM:pem
                                header:@"-----BEGIN PRIVATE KEY-----"
                                footer:@"-----END PRIVATE KEY-----"];
        if (derData) {
            NSData *stripped = [self stripPKCS8Wrapper:derData];
            if (stripped) derData = stripped;
        }
    }
    if (!derData) return nil;

    NSDictionary *attrs = @{
        (id)kSecAttrKeyType:       (id)kSecAttrKeyTypeRSA,
        (id)kSecAttrKeyClass:      (id)kSecAttrKeyClassPrivate,
        (id)kSecAttrKeySizeInBits: @2048,
    };

    CFErrorRef error = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)derData,
                                         (__bridge CFDictionaryRef)attrs,
                                         &error);
    if (error) {
        SVLogError(@"SignatureVerifier: SecKeyCreateWithData (private) error: %@", (__bridge NSError *)error);
        CFRelease(error);
    }
    return key;
}

#pragma mark - Sign / Verify

+ (NSData *)signHash:(NSData *)hashData privateKeyRef:(SecKeyRef)privKey {
    CFErrorRef error = NULL;
    CFDataRef sigRef = SecKeyCreateSignature(privKey,
                                             kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA256,
                                             (__bridge CFDataRef)hashData,
                                             &error);
    if (error) {
        CFRelease(error);
        return nil;
    }
    NSData *result = (__bridge_transfer NSData *)sigRef;
    return result;
}

+ (BOOL)verifyHash:(NSData *)hashData withSignature:(NSData *)signatureData publicKeyRef:(SecKeyRef)pubKey {
    CFErrorRef error = NULL;
    BOOL result = SecKeyVerifySignature(pubKey,
                                 kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA256,
                                 (__bridge CFDataRef)hashData,
                                 (__bridge CFDataRef)signatureData,
                                 &error);
    if (error) {
        SVLogError(@"SignatureVerifier: SecKeyVerifySignature error: %@", (__bridge NSError *)error);
        CFRelease(error);
    }
    return result;
}

#pragma mark - Embedded Key (runtime)

+ (SecKeyRef)createEmbeddedPublicKeyRef {
    if (strlen(EMBEDDED_PUBLIC_KEY) == 0) {
        SVLogError(@"SignatureVerifier: EMBEDDED_PUBLIC_KEY is empty");
        return nil;
    }

    NSString *pemStr = [NSString stringWithUTF8String:EMBEDDED_PUBLIC_KEY];
    NSData *derData = [self derDataFromPEM:pemStr
                                    header:@"-----BEGIN PUBLIC KEY-----"
                                    footer:@"-----END PUBLIC KEY-----"];
    if (!derData) {
        SVLogError(@"SignatureVerifier: derDataFromPEM returned nil for embedded public key");
        return nil;
    }

    SVLogInfo(@"SignatureVerifier: DER data length=%lu for embedded public key", (unsigned long)derData.length);

    NSDictionary *attrs = @{
        (id)kSecAttrKeyType:       (id)kSecAttrKeyTypeRSA,
        (id)kSecAttrKeyClass:      (id)kSecAttrKeyClassPublic,
        (id)kSecAttrKeySizeInBits: @2048,
    };

    CFErrorRef error = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)derData,
                                         (__bridge CFDictionaryRef)attrs,
                                         &error);
    if (error) {
        SVLogError(@"SignatureVerifier: SecKeyCreateWithData failed for public key: %@", (__bridge NSError *)error);
        CFRelease(error);
    }
    return key;
}

+ (SecKeyRef _Nullable)createPublicKeyRef {
    static SecKeyRef sCachedKey = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sCachedKey = [self createEmbeddedPublicKeyRef];
        if (!sCachedKey) {
            SVLogError(@"SignatureVerifier: createEmbeddedPublicKeyRef returned nil, EMBEDDED_PUBLIC_KEY length=%zu", strlen(EMBEDDED_PUBLIC_KEY));
        } else {
            SVLogInfo(@"SignatureVerifier: public key loaded successfully");
        }
    });
    return sCachedKey;
}

+ (BOOL)verifyHash:(NSData *)hashData withSignature:(NSData *)signatureData {
    SecKeyRef pubKey = [self createPublicKeyRef];
    if (!pubKey) {
        SVLogError(@"SignatureVerifier: no public key available for verification");
        return NO;
    }
    return [self verifyHash:hashData withSignature:signatureData publicKeyRef:pubKey];
}

+ (BOOL)verifyMachOAtPath:(NSString *)path {
#ifdef DEBUG
    SVLogInfo(@"SignatureVerifier: DEBUG build, skipping verification for %@", path);
    return YES;
#else
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        SVLogError(@"SignatureVerifier: cannot read file at path: %@", path);
        return NO;
    }

    SVLogInfo(@"SignatureVerifier: read %lu bytes from %@", (unsigned long)data.length, path);

    uint32_t magic = *(uint32_t *)data.bytes;
    BOOL isFat = (magic == FAT_MAGIC || magic == FAT_CIGAM || magic == FAT_MAGIC_64 || magic == FAT_CIGAM_64);

    if (isFat) {
        const uint8_t *bytes = (const uint8_t *)data.bytes;
        BOOL needsSwap = (magic == FAT_CIGAM || magic == FAT_CIGAM_64);
        BOOL is64 = (magic == FAT_MAGIC_64 || magic == FAT_CIGAM_64);

        struct fat_header header;
        memcpy(&header, bytes, sizeof(header));
        uint32_t nfat_arch = needsSwap ? OSSwapBigToHostInt32(header.nfat_arch) : header.nfat_arch;

        SVLogInfo(@"SignatureVerifier: fat binary, %u architectures", nfat_arch);

        size_t archEntrySize = is64 ? sizeof(struct fat_arch_64) : sizeof(struct fat_arch);
        const uint8_t *archPtr = bytes + sizeof(struct fat_header);

        for (uint32_t i = 0; i < nfat_arch; i++) {
            uint32_t archOffset;
            if (is64) {
                struct fat_arch_64 arch;
                memcpy(&arch, archPtr, sizeof(arch));
                archOffset = (uint32_t)(needsSwap ? OSSwapBigToHostInt64(arch.offset) : arch.offset);
            } else {
                struct fat_arch arch;
                memcpy(&arch, archPtr, sizeof(arch));
                archOffset = needsSwap ? OSSwapBigToHostInt32(arch.offset) : arch.offset;
            }

            SVLogInfo(@"SignatureVerifier: arch %u offset=%u", i, archOffset);

            NSData *hash = [self calculateTextSegmentHash:data archOffset:archOffset];
            if (!hash) {
                SVLogError(@"SignatureVerifier: arch %u calculateTextSegmentHash returned nil", i);
                return NO;
            }

            NSMutableString *hashHex = [NSMutableString stringWithCapacity:hash.length * 2];
            const uint8_t *hBytes = (const uint8_t *)hash.bytes;
            for (NSUInteger k = 0; k < hash.length; k++) {
                [hashHex appendFormat:@"%02x", hBytes[k]];
            }
            SVLogInfo(@"SignatureVerifier: arch %u hash=%@", i, hashHex);

            NSData *signature = [self readSignatureFromMachO:data archOffset:archOffset];
            if (!signature) {
                SVLogError(@"SignatureVerifier: arch %u readSignatureFromMachO returned nil (section empty or not found)", i);
                return NO;
            }
            SVLogInfo(@"SignatureVerifier: arch %u signature length=%lu", i, (unsigned long)signature.length);

            if (![self verifyHash:hash withSignature:signature]) {
                SVLogError(@"SignatureVerifier: arch %u SecKeyVerifySignature FAILED", i);
                return NO;
            }
            SVLogInfo(@"SignatureVerifier: arch %u signature valid", i);
            archPtr += archEntrySize;
        }
        return YES;
    } else if (magic == MH_MAGIC || magic == MH_MAGIC_64 || magic == MH_CIGAM || magic == MH_CIGAM_64) {
        SVLogInfo(@"SignatureVerifier: thin binary (single arch)");

        NSData *hash = [self calculateTextSegmentHash:data archOffset:0];
        if (!hash) {
            SVLogError(@"SignatureVerifier: calculateTextSegmentHash returned nil");
            return NO;
        }

        NSMutableString *hashHex = [NSMutableString stringWithCapacity:hash.length * 2];
        const uint8_t *hBytes = (const uint8_t *)hash.bytes;
        for (NSUInteger k = 0; k < hash.length; k++) {
            [hashHex appendFormat:@"%02x", hBytes[k]];
        }
        SVLogInfo(@"SignatureVerifier: hash=%@", hashHex);

        NSData *signature = [self readSignatureFromMachO:data archOffset:0];
        if (!signature) {
            SVLogError(@"SignatureVerifier: readSignatureFromMachO returned nil (section empty or not found)");
            return NO;
        }
        SVLogInfo(@"SignatureVerifier: signature length=%lu", (unsigned long)signature.length);

        BOOL result = [self verifyHash:hash withSignature:signature];
        if (!result) {
            SVLogError(@"SignatureVerifier: SecKeyVerifySignature FAILED");
        } else {
            SVLogInfo(@"SignatureVerifier: signature valid");
        }
        return result;
    }

    SVLogError(@"SignatureVerifier: unknown Mach-O format, magic=0x%08x", magic);
    return NO;
#endif
}

@end
