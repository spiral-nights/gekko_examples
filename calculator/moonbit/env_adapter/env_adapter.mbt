///|
fn __to_int32(x : Int64) -> Int {
  if x < -2147483648L || x > 2147483647L {
    abort("Int64 out of Int32 range")
  }
  x.to_int()
}

///|
pub fn args() -> @gprelude.GList[String] {
  @gprelude.GList::from_array((@moonbitlang_core_env.args())[:])
}

///|
pub fn current_dir() -> String? {
  @moonbitlang_core_env.current_dir()
}

///|
pub fn[T] exit(x : Int64) -> T {
  @moonbitlang_core_env.exit(__to_int32(x))
}

///|
pub fn get_env_var(x : String) -> String? {
  @moonbitlang_core_env.get_env_var(x)
}

///|
pub fn now() -> Int64 {
  (@moonbitlang_core_env.now()).reinterpret_as_int64()
}

///|
pub fn rand(x : Int64) -> @gprelude.BitArray? {
  (@moonbitlang_core_env.rand(__to_int32(x))).map(fn(x0) { @gprelude.BitArray::from_bytes(x0) })
}
