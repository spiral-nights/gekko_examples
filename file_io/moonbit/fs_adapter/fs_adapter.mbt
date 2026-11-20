///|
pub fn create_dir(x : String) -> Result[Unit, String] {
  try {
    let __res = @moonbitlang_x_fs.create_dir(x)
    Ok(__res)
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn is_dir(x : String) -> Result[Bool, String] {
  try {
    let __res = @moonbitlang_x_fs.is_dir(x)
    Ok(__res)
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn is_file(x : String) -> Result[Bool, String] {
  try {
    let __res = @moonbitlang_x_fs.is_file(x)
    Ok(__res)
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn read_dir(x : String) -> Result[@gprelude.GList[String], String] {
  try {
    let __res = @moonbitlang_x_fs.read_dir(x)
    Ok(@gprelude.GList::from_array(__res))
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn read_file_to_bytes(x : String) -> Result[@gprelude.BitArray, String] {
  try {
    let __res = @moonbitlang_x_fs.read_file_to_bytes(x)
    Ok(@gprelude.BitArray::from_bytes(__res))
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn read_file_to_string(arg0 : String, encoding : String?) -> Result[String, String] {
  try {
    let __res = @moonbitlang_x_fs.read_file_to_string(arg0, encoding?=encoding)
    Ok(__res)
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn remove_dir(x : String) -> Result[Unit, String] {
  try {
    let __res = @moonbitlang_x_fs.remove_dir(x)
    Ok(__res)
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn remove_file(x : String) -> Result[Unit, String] {
  try {
    let __res = @moonbitlang_x_fs.remove_file(x)
    Ok(__res)
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn write_bytes_to_file(arg0 : String, arg1 : @gprelude.BitArray) -> Result[Unit, String] {
  try {
    let __res = @moonbitlang_x_fs.write_bytes_to_file(arg0, (arg1).data)
    Ok(__res)
  } catch {
    __err => Err(Error::to_string(__err))
  }
}

///|
pub fn write_string_to_file(arg0 : String, arg1 : String, encoding : String?) -> Result[Unit, String] {
  try {
    let __res = @moonbitlang_x_fs.write_string_to_file(arg0, arg1, encoding?=encoding)
    Ok(__res)
  } catch {
    __err => Err(Error::to_string(__err))
  }
}
