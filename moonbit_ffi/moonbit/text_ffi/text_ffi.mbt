///|
pub fn shout(s : String) -> String {
  s.to_upper() + "!"
}

///|
pub fn upper_all(xs : @gprelude.GList[String]) -> @gprelude.GList[String] {
  let arr = xs.to_array().map(fn(s) { s.to_upper() })
  @gprelude.GList::from_array(arr[:])
}

///|
pub fn sum_squares(xs : @gprelude.GList[Int64]) -> Int64 {
  for cur = xs, acc = 0L {
    match cur {
      @gprelude.Nil => break acc
      @gprelude.Cons(h, t) => continue t, acc + h * h
    }
  }
}
