import Foundation

struct Xattr {

  /** Error type */
  struct Error: Swift.Error {

    // todo: at the time of calling this property the `errno` could be lost already. instead need to store error code.
    let localizedDescription = String(utf8String: strerror(errno))
  }

  /**
    Set extended attribute at path

    - Parameters:
      - name: Name of extended attribute
      - data: Data associated with the attribute
      - path: Path to file, directory, symlink etc
  */
  static func set(named name: String, data: Data, atPath path: String) throws {

    if setxattr(path, name, (data as NSData).bytes, data.count, 0, 0) == -1 { throw Error() }
  }

  /**
   Remove extended attribute at path

   - Parameters:
     - name: Name of extended attribute
     - path: Path to file, directory, symlink etc
   */
  static func remove(named name: String, atPath path: String) throws {

    if removexattr(path, name, 0) == -1 { throw Error() }
  }

  /**
    Get data for extended attribute at path

    - Parameters:
      - name: Name of extended attribute
      - path: Path to file, directory, symlink etc
  */
  static func dataFor(named name: String, atPath path: String) throws -> Data {

    let bufLength = getxattr(path, name, nil, 0, 0, 0)

    // todo: memory leak `buf` in case of `getxattr` fail. Unsafe pointers are not under ARC or something.
    guard bufLength != -1, let buf = malloc(bufLength), getxattr(path, name, buf, bufLength, 0, 0) != -1 else { throw Error() }

    // todo: memory leak `buf`: `Data` just copies buffer - it doesn't owns or releases buf.
    return Data(bytes: buf, count: bufLength)
  }

  /**
    Get names of extended attributes at path

    - Parameters:
      - path: Path to file, directory, symlink etc
  */
  static func names(atPath path: String) throws -> [String]? {

    let bufLength = listxattr(path, nil, 0, 0)

    guard bufLength != -1 else { throw Error() }

    // todo: memory leak of `buf` - below `NSString` just copies bytes.
    let buf = UnsafeMutablePointer<Int8>.allocate(capacity: bufLength)

    guard listxattr(path, buf, bufLength, 0) != -1 else { throw Error() }

    var names = NSString(bytes: buf, length: bufLength, encoding: String.Encoding.utf8.rawValue)?.components(separatedBy: "\0")

    names?.removeLast()

    return names
  }
}
