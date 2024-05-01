//
//  main.m
//  X-SignatureTool
//
//  Created by lyq1996 on 2024/3/23.
//

#import <Foundation/Foundation.h>

static const char *version = "1.0.0";

static void print_help(char * const *argv, FILE *file) {
    fprintf(file, "Usage: \n\t%s [-hv] <-d | -e> <-k key> <target mach-o file>\n", argv[0]);
}

static void check_signature(const char *macho, const char *key) {
    
}

static void write_signature(const char *macho, const char *key) {
    
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
                case 'd':
                    d_flag = 1;
                    break;
                case 'e':
                    e_flag = 1;
                    break;
                case 'k':
                    key = optarg;
                    break;
                case 'h':
                    print_help(argv, stdout);
                    exit(EXIT_SUCCESS);
                case 'v':
                    printf("%s version: %s\n", argv[0], version);
                    exit(EXIT_SUCCESS);
                case '?':
                    print_help(argv, stderr);
                    exit(EXIT_FAILURE);
                default:
                    print_help(argv, stderr);
                    exit(EXIT_FAILURE);
            }
        }

        // Check option exist
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
