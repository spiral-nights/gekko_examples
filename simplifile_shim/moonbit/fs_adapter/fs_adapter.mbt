///|
pub fn create_dir(x : StringView) -> Result[Unit, StringView] {
  try {
    let __res = @moonbitlang_x_fs.create_dir((x).to_owned())
    Ok(__res)
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn is_dir(x : StringView) -> Result[Bool, StringView] {
  try {
    let __res = @moonbitlang_x_fs.is_dir((x).to_owned())
    Ok(__res)
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn is_file(x : StringView) -> Result[Bool, StringView] {
  try {
    let __res = @moonbitlang_x_fs.is_file((x).to_owned())
    Ok(__res)
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn path_exists(x : StringView) -> Bool {
  @moonbitlang_x_fs.path_exists((x).to_owned())
}

///|
pub fn read_dir(x : StringView) -> Result[@gprelude.GList[StringView], StringView] {
  try {
    let __res = @moonbitlang_x_fs.read_dir((x).to_owned())
    Ok(@gprelude.GList::from_array((__res).map(fn(x0) { (x0).to_string_view() })[:]))
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn read_file_to_bytes(x : StringView) -> Result[@gprelude.BitArray, StringView] {
  try {
    let __res = @moonbitlang_x_fs.read_file_to_bytes((x).to_owned())
    Ok(@gprelude.BitArray::from_bytes(__res))
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn read_file_to_string(arg0 : StringView, encoding : StringView?) -> Result[StringView, StringView] {
  try {
    let __res = @moonbitlang_x_fs.read_file_to_string((arg0).to_owned(), encoding?=(encoding).map(fn(x0) { (x0).to_owned() }))
    Ok((__res).to_string_view())
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn remove_dir(x : StringView) -> Result[Unit, StringView] {
  try {
    let __res = @moonbitlang_x_fs.remove_dir((x).to_owned())
    Ok(__res)
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn remove_file(x : StringView) -> Result[Unit, StringView] {
  try {
    let __res = @moonbitlang_x_fs.remove_file((x).to_owned())
    Ok(__res)
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn write_bytes_to_file(arg0 : StringView, arg1 : @gprelude.BitArray) -> Result[Unit, StringView] {
  try {
    let __res = @moonbitlang_x_fs.write_bytes_to_file((arg0).to_owned(), (arg1).data)
    Ok(__res)
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn write_string_to_file(arg0 : StringView, arg1 : StringView, encoding : StringView?) -> Result[Unit, StringView] {
  try {
    let __res = @moonbitlang_x_fs.write_string_to_file((arg0).to_owned(), (arg1).to_owned(), encoding?=(encoding).map(fn(x0) { (x0).to_owned() }))
    Ok(__res)
  } catch {
    __err => Err((Error::to_string(__err)).to_string_view())
  }
}

///|
pub fn ioerror_ioerror(arg0 : StringView) -> @moonbitlang_x_fs.IOError {
  @moonbitlang_x_fs.IOError((arg0).to_owned())
}

///|
pub fn[Ret] match_ioerror(value : @moonbitlang_x_fs.IOError, on_ioerror : (StringView) -> Ret) -> Ret {
  match value {
    @moonbitlang_x_fs.IOError(v0) => on_ioerror((v0).to_string_view())
  }
}
