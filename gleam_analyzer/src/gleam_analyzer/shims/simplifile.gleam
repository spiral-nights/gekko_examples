import ffi/fs
import gleam/bit_array
import gleam/list
import gleam/result
import gleam/string
import simplifile.{
  type FileError, type FileInfo, Eexist, Enoent, Eopnotsupp, FileInfo, Unknown,
}

fn map_fs_error(err: String) -> FileError {
  let lower = string.lowercase(err)
  case
    string.contains(lower, "enoent")
    || string.contains(lower, "no such file")
    || string.contains(lower, "not found")
  {
    True -> Enoent
    False ->
      case
        string.contains(lower, "eexist")
        || string.contains(lower, "already exists")
      {
        True -> Eexist
        False -> Unknown(err)
      }
  }
}

fn join_path(dir: String, entry: String) -> String {
  case string.ends_with(dir, "/") || dir == "" {
    True -> dir <> entry
    False -> dir <> "/" <> entry
  }
}

/// @patch("simplifile:simplifile.read_bits")
pub fn read_bits(from filepath: String) -> Result(BitArray, FileError) {
  fs.read_file_to_bytes(filepath)
  |> result.map_error(map_fs_error)
}

/// @patch("simplifile:simplifile.write_bits")
pub fn write_bits(
  to filepath: String,
  bits bits: BitArray,
) -> Result(Nil, FileError) {
  fs.write_bytes_to_file(filepath, bits)
  |> result.map_error(map_fs_error)
}

/// @patch("simplifile:simplifile.append_bits")
pub fn append_bits(
  to filepath: String,
  bits bits: BitArray,
) -> Result(Nil, FileError) {
  use existing <- result.try(case fs.path_exists(filepath) {
    True -> read_bits(from: filepath)
    False -> Ok(<<>>)
  })
  write_bits(to: filepath, bits: <<existing:bits, bits:bits>>)
}

/// @patch("simplifile:simplifile.delete_file")
pub fn delete_file(at path: String) -> Result(Nil, FileError) {
  fs.remove_file(path)
  |> result.map_error(map_fs_error)
}

/// @patch("simplifile:simplifile.delete")
pub fn delete(file_or_dir_at path: String) -> Result(Nil, FileError) {
  case fs.path_exists(path) {
    False -> Error(Enoent)
    True -> {
      use is_dir <- result.try(
        fs.is_dir(path)
        |> result.map_error(map_fs_error),
      )
      case is_dir {
        True -> {
          use entries <- result.try(
            fs.read_dir(path)
            |> result.map_error(map_fs_error),
          )
          use _ <- result.try(
            list.try_each(entries, fn(entry) { delete(join_path(path, entry)) }),
          )
          fs.remove_dir(path)
          |> result.map_error(map_fs_error)
        }
        False -> delete_file(at: path)
      }
    }
  }
}

/// @patch("simplifile:simplifile.create_directory")
pub fn create_directory(filepath: String) -> Result(Nil, FileError) {
  fs.create_dir(filepath)
  |> result.map_error(map_fs_error)
}

/// @patch("simplifile:simplifile.do_create_dir_all")
pub fn do_create_dir_all(dirpath: String) -> Result(Nil, FileError) {
  let is_abs = string.starts_with(dirpath, "/")
  let initial_prefix = case is_abs {
    True -> "/"
    False -> ""
  }
  let segments =
    dirpath
    |> string.split("/")
    |> list.filter(fn(seg) { seg != "" && seg != "." })
  create_dir_segments(initial_prefix, segments)
}

fn create_dir_segments(
  prefix: String,
  segments: List(String),
) -> Result(Nil, FileError) {
  case segments {
    [] -> Ok(Nil)
    [seg, ..rest] -> {
      let next = join_path(prefix, seg)
      use _ <- result.try(case fs.path_exists(next) {
        True -> Ok(Nil)
        False ->
          fs.create_dir(next)
          |> result.map_error(map_fs_error)
      })
      create_dir_segments(next, rest)
    }
  }
}

/// @patch("simplifile:simplifile.read_directory")
pub fn read_directory(at path: String) -> Result(List(String), FileError) {
  fs.read_dir(path)
  |> result.map_error(map_fs_error)
}

/// @patch("simplifile:simplifile.is_file")
pub fn is_file(filepath: String) -> Result(Bool, FileError) {
  case fs.path_exists(filepath) {
    False -> Ok(False)
    True ->
      fs.is_file(filepath)
      |> result.map_error(map_fs_error)
  }
}

/// @patch("simplifile:simplifile.is_directory")
pub fn is_directory(filepath: String) -> Result(Bool, FileError) {
  case fs.path_exists(filepath) {
    False -> Ok(False)
    True ->
      fs.is_dir(filepath)
      |> result.map_error(map_fs_error)
  }
}

/// @patch("simplifile:simplifile.exists")
pub fn exists(
  filepath filepath: String,
  follow_links follow_links: Bool,
) -> Result(Bool, FileError) {
  let _ = follow_links
  Ok(fs.path_exists(filepath))
}

/// @patch("simplifile:simplifile.file_info")
pub fn file_info(filepath: String) -> Result(FileInfo, FileError) {
  case fs.path_exists(filepath) {
    False -> Error(Enoent)
    True -> {
      use is_dir <- result.try(
        fs.is_dir(filepath)
        |> result.map_error(map_fs_error),
      )
      case is_dir {
        True ->
          Ok(FileInfo(
            size: 0,
            mode: 0o40755,
            nlinks: 1,
            inode: 0,
            user_id: 0,
            group_id: 0,
            dev: 0,
            atime_seconds: 0,
            mtime_seconds: 0,
            ctime_seconds: 0,
          ))
        False -> {
          use bytes <- result.try(read_bits(from: filepath))
          Ok(FileInfo(
            size: bit_array.byte_size(bytes),
            mode: 0o100644,
            nlinks: 1,
            inode: 0,
            user_id: 0,
            group_id: 0,
            dev: 0,
            atime_seconds: 0,
            mtime_seconds: 0,
            ctime_seconds: 0,
          ))
        }
      }
    }
  }
}

/// @patch("simplifile:simplifile.link_info")
pub fn link_info(filepath: String) -> Result(FileInfo, FileError) {
  file_info(filepath)
}

/// @patch("simplifile:simplifile.create_symlink")
pub fn create_symlink(
  to target: String,
  from symlink: String,
) -> Result(Nil, FileError) {
  let _ = target
  let _ = symlink
  Error(Eopnotsupp)
}

/// @patch("simplifile:simplifile.create_link")
pub fn create_link(
  to target: String,
  from link: String,
) -> Result(Nil, FileError) {
  let _ = target
  let _ = link
  Error(Eopnotsupp)
}

/// @patch("simplifile:simplifile.do_copy_file")
pub fn do_copy_file(src: String, dest: String) -> Result(Int, FileError) {
  use bits <- result.try(read_bits(from: src))
  use _ <- result.try(write_bits(to: dest, bits: bits))
  Ok(bit_array.byte_size(bits))
}

/// @patch("simplifile:simplifile.rename_file")
pub fn rename_file(at src: String, to dest: String) -> Result(Nil, FileError) {
  rename(at: src, to: dest)
}

/// @patch("simplifile:simplifile.rename")
pub fn rename(at src: String, to dest: String) -> Result(Nil, FileError) {
  case fs.path_exists(src) {
    False -> Error(Enoent)
    True -> {
      use is_dir <- result.try(
        fs.is_dir(src)
        |> result.map_error(map_fs_error),
      )
      case is_dir {
        True -> {
          use entries <- result.try(
            fs.read_dir(src)
            |> result.map_error(map_fs_error),
          )
          use _ <- result.try(do_create_dir_all(dest <> "/"))
          use _ <- result.try(
            list.try_each(entries, fn(entry) {
              rename(at: join_path(src, entry), to: join_path(dest, entry))
            }),
          )
          fs.remove_dir(src)
          |> result.map_error(map_fs_error)
        }
        False -> {
          use _ <- result.try(do_copy_file(src, dest))
          delete_file(at: src)
        }
      }
    }
  }
}

/// @patch("simplifile:simplifile.set_permissions_octal")
pub fn set_permissions_octal(
  for_file_at filepath: String,
  to permissions: Int,
) -> Result(Nil, FileError) {
  let _ = permissions
  case fs.path_exists(filepath) {
    False -> Error(Enoent)
    True -> Error(Eopnotsupp)
  }
}

/// @patch("simplifile:simplifile.erl_do_current_directory")
pub fn erl_do_current_directory() -> Result(List(UtfCodepoint), FileError) {
  Error(Eopnotsupp)
}

/// @patch("simplifile:simplifile.do_resolve")
pub fn do_resolve(path: String) -> String {
  path
}

/// @patch("simplifile:simplifile.touch")
pub fn touch(at path: String) -> Result(Nil, FileError) {
  case fs.path_exists(path) {
    True -> {
      use bits <- result.try(read_bits(from: path))
      write_bits(to: path, bits: bits)
    }
    False -> write_bits(to: path, bits: <<>>)
  }
}
