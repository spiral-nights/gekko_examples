///|
fn __to_int32(x : Int64) -> Int {
  if x < -2147483648L || x > 2147483647L {
    abort("Int64 out of Int32 range")
  }
  x.to_int()
}

///|
pub fn args() -> @gprelude.GList[StringView] {
  @gprelude.GList::from_array((@moonbitlang_core_env.args()).map(fn(x0) { (x0).to_string_view() })[:])
}

///|
pub fn current_dir() -> StringView? {
  (@moonbitlang_core_env.current_dir()).map(fn(x0) { (x0).to_string_view() })
}

///|
pub fn[T] exit(x : Int64) -> T {
  @moonbitlang_core_env.exit(__to_int32(x))
}

///|
pub fn get_env_var(x : StringView) -> StringView? {
  (@moonbitlang_core_env.get_env_var((x).to_owned())).map(fn(x0) { (x0).to_string_view() })
}

///|
pub fn get_env_vars() -> Map[StringView, StringView] {
  { let map0 = Map([]); (@moonbitlang_core_env.get_env_vars()).each(fn(mk0, mv0) { map0[(mk0).to_string_view()] = (mv0).to_string_view() }); map0 }
}

///|
pub fn now() -> Int64 {
  (@moonbitlang_core_env.now()).reinterpret_as_int64()
}

///|
pub fn rand(x : Int64) -> @gprelude.BitArray? {
  (@moonbitlang_core_env.rand(__to_int32(x))).map(fn(x0) { @gprelude.BitArray::from_bytes(x0) })
}

///|
pub fn set_env_var(arg0 : StringView, arg1 : StringView) -> Unit {
  @moonbitlang_core_env.set_env_var((arg0).to_owned(), (arg1).to_owned())
}

///|
pub fn unset_env_var(x : StringView) -> Unit {
  @moonbitlang_core_env.unset_env_var((x).to_owned())
}
