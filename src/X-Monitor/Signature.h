//
//  Signature.h
//  X-Monitor
//
//  Created by lyq1996 on 2024/3/23.
//

#ifndef Signature_h
#define Signature_h

/*
 I don't have "Endpoint Security" entitlement,
 so the X-Monitor was left in None Team and adhoc signing.
 
 In this scenario, the daemon(X-Service and X-Helper) needs a way to verify the peer
 when peer trying to create a XPC connection to the daemon.
 
 So here is a trick.
 The following char array was used to store the custom signature,
 and the signature is caculated by encrypting the __TEXT segment hash with the RSA private key.
 
 The private/public key was dynamic generated in each build using xcode PreActions script,
 and the public key will be write into daemon source in hardcode.
 
 Daemon will parser the client MACH-O file, and decrypted the signature using the hardcoded public key
 and compare decrypted hash with the computed hash of __TEXT segment to decline untrusted XPC connection.
 */
__attribute__((used))
__attribute__((section("__X_CUSTOM, __SIGNATURE")))
static const char signature[256];


#endif /* CustomCodesign_h */
