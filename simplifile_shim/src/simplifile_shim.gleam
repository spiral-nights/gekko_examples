import filepath
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() -> Nil {
  let root = "simplifile_demo_tmp"
  let nested = filepath.join(root, "sub")
  let file_path = filepath.join(nested, "note.txt")

  let _ = simplifile.delete(file_or_dir_at: root)

  let assert Ok(Nil) = simplifile.create_directory_all(nested)
  assert simplifile.is_directory(nested) == Ok(True)

  let assert Ok(Nil) = simplifile.write(to: file_path, contents: "hello ")
  let assert Ok(Nil) = simplifile.append(to: file_path, contents: "gekko")
  assert simplifile.is_file(file_path) == Ok(True)

  let assert Ok(content) = simplifile.read(from: file_path)
  assert content == "hello gekko"

  let assert Ok(entries) = simplifile.read_directory(at: nested)
  let sorted = list.sort(entries, string.compare)
  assert sorted == ["note.txt"]

  let missing_is_err = case
    simplifile.read(from: filepath.join(root, "missing.txt"))
  {
    Error(_) -> True
    Ok(_) -> False
  }
  assert missing_is_err == True

  let assert Ok(Nil) = simplifile.delete(file_or_dir_at: root)
  assert simplifile.is_directory(root) == Ok(False)

  io.println("joined=" <> file_path)
  io.println("content=" <> content)
  io.println("entries=" <> string.join(sorted, ","))
  io.println("missing_is_err=True")
  io.println("cleaned=True")
}
