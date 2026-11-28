///|
pub fn utf16_length(s : StringView) -> Int64 {
  s.length().to_int64()
}

///|
pub fn utf16_slice(s : StringView, start : Int64, length : Int64) -> StringView {
  if length <= 0L {
    return ""
  }
  let total = s.length()
  let st = if start <= 0L {
    0
  } else if start >= total.to_int64() {
    total
  } else {
    start.to_int()
  }
  let max_len = total - st
  let take = if length >= max_len.to_int64() {
    max_len
  } else {
    length.to_int()
  }
  if take <= 0 {
    ""
  } else {
    s.unsafe_view(start=st, end=st + take)
  }
}

///|
pub fn utf16_drop_one(s : StringView) -> StringView {
  let len = s.length()
  if len <= 1 {
    ""
  } else {
    s.unsafe_view(start=1, end=len)
  }
}

///|
pub fn find_first(
  haystack : StringView,
  patterns : @gprelude.GList[StringView],
) -> (Int64, Int64)? {
  let mut best : (Int, Int)? = None
  for cur = patterns {
    match cur {
      @gprelude.Nil => break
      @gprelude.Cons(pat, rest) => {
        if pat.length() > 0 {
          match haystack.find(pat) {
            Some(idx) => {
              let pat_len = pat.length()
              match best {
                None => best = Some((idx, pat_len))
                Some((best_idx, _)) =>
                  if idx < best_idx {
                    best = Some((idx, pat_len))
                  }
              }
            }
            None => ()
          }
        }
        continue rest
      }
    }
  }
  match best {
    None => None
    Some((idx, len)) => Some((idx.to_int64(), len.to_int64()))
  }
}
