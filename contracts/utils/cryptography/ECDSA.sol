// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @title Elliptic curve signature operations
 * @dev Based on
 * https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d and https://github.com/OpenZeppelin/openzeppelin-contracts
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Recover signer address from a message by
     * using their signature. What is recovered is the signer address.
     * @param hash bytes32 message, the hash is the signed message.
     * @param signature bytes signature, the signature is generated using metrimask.rpcProvider.signMessage()
     *
     */
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        view
        returns (address, RecoverError)
    {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;
        // ecrecover takes the signature parameters,
        // and the only way to get them
        // currently is to use assembly.
        assembly {
            v := byte(0, mload(add(signature, 0x20)))
            r := mload(add(signature, 0x21))
            s := mload(add(signature, 0x41))
        }
        // EIP-2 still allows signature malleability for
        // ecrecover(). Remove this possibility and
        // make the signature
        // unique. Appendix F in the Ethereum Yellow paper
        // (https://ethereum.github.io/yellowpaper/paper.pdf),
        // defines the valid range for s in (281):
        // 0 < s < secp256k1n ÷ 2 + 1,
        // and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a
        // unique signature with an s-value in the lower
        // half order.
        //
        // If your library generates malleable signatures,
        // such as s-values in the upper range, calculate
        // a new s-value with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
        // - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures
        // with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignature);
        }
        // Support both compressed or uncompressed
        if (v != 27 && v != 28 && v != 31 && v != 32) {
            return (address(0), RecoverError.InvalidSignature);
        }
        // If the signature is valid (and not malleable),
        // return the signer address
        return btc_ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `btc_ecrecover` precompiled contract allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        view
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        (address signer, RecoverError err) = btc_ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (
                address(0),
                err != RecoverError.NoError
                    ? RecoverError.InvalidSignature
                    : err
            );
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function btc_ecrecover(
        bytes32 msgh,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (address, RecoverError) {
        uint256[4] memory input;
        input[0] = uint256(msgh);
        input[1] = uint256(v);
        input[2] = uint256(r);
        input[3] = uint256(s);
        uint256[1] memory retval;
        uint256 success;
        assembly {
            success := staticcall(not(0), 0x85, input, 0x80, retval, 0x20)
        }
        if (success != 1) {
            return (address(0), RecoverError.InvalidSignature);
        }
        return (address(uint160(retval[0])), RecoverError.NoError);
    }

    /**
     * @dev Returns an Metrix Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed
     *
     * See {recover}.
     */
    function toMrxSignedMessageHash(bytes32 hash)
        public
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            sha256(
                abi.encodePacked(
                    sha256(
                        abi.encodePacked(
                            "\x17Metrix Signed Message:\n\x32",
                            hash
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the Metrix RPC or MetriMask RPC
     * one caveat is that the message cannot exceed 16384 bytes
     *
     * See {recover}.
     */
    function toMrxSignedMessageHash(bytes memory s)
        public
        pure
        returns (bytes32)
    {
        require(s.length <= 0xffff, "ECDSA: value out of range");
        if (s.length < 0xfd) {
            return
                sha256(
                    abi.encodePacked(
                        sha256(
                            abi.encodePacked(
                                "\x17Metrix Signed Message:\n",
                                bytes1(uint8(s.length)),
                                s
                            )
                        )
                    )
                );
        }

        return
            sha256(
                abi.encodePacked(
                    sha256(
                        abi.encodePacked(
                            "\x17Metrix Signed Message:\n\xfd",
                            bytes2(uint16(s.length))[1],
                            bytes2(uint16(s.length))[0],
                            s
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns an Metrix Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x17\x01", domainSeparator, structHash)
            );
    }
}
