///|
pub fn repeat_utf8_byte_size(s : String, times : Int64) -> Int64 {
  let buf = @buffer.Buffer()
  let n = times.to_int()
  let mut i = 0
  while i < n {
    buf.write_string_utf8(s[:])
    i = i + 1
  }
  @gprelude.BitArray::from_bytes(buf.to_bytes()).byte_size()
}
