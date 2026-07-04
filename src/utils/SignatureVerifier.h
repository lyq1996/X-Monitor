//
//  SignatureVerifier.h
//  X-Service
//
//  Created by lyq1996 on 2024/3/23.
//

#ifndef SignatureVerifier_h
#define SignatureVerifier_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignatureVerifier : NSObject

+ (NSData * _Nullable)calculateTextSegmentHash:(NSData *)machoData archOffset:(uint32_t)offset;
+ (int)findCustomSignatureSection:(NSData *)machoData
                       archOffset:(uint32_t)offset
                    sectionOffset:(uint32_t *)outOffset
                     sectionSize:(uint32_t *)outSize;
+ (NSData * _Nullable)readSignatureFromMachO:(NSData *)machoData archOffset:(uint32_t)offset;

+ (BOOL)verifyMachOAtPath:(NSString *)path;
+ (BOOL)verifyHash:(NSData *)hashData withSignature:(NSData *)signatureData publicKeyRef:(SecKeyRef)pubKey;

+ (SecKeyRef _Nullable)createPublicKeyFromPEMFile:(NSString *)pemPath;
+ (SecKeyRef _Nullable)createPrivateKeyFromPEMFile:(NSString *)pemPath;
+ (NSData * _Nullable)signHash:(NSData *)hashData privateKeyRef:(SecKeyRef)privKey;

@end

NS_ASSUME_NONNULL_END

#endif
