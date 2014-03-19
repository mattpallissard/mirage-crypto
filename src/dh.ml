open Common

type params = {
  p  : Z.t ;   (* The prime modulus *)
  gg : Z.t ;   (* Group generator *)
}

type secret = { x : Z.t }

let to_cstruct { p; _ } z =
  Numeric.Z.(to_cstruct_be ~size:(cdiv (bits p) 8) z)

let params ~p ~gg = { p; gg }

(* XXX see Rng.prime *)
let gen_params ?g bits =
  let p  = Rng.prime ?g bits in
  let gg = Rng.Z.gen_r ?g z_two p in
  { p; gg }

let gen_secret ?g ({ p; gg } as param) =
  let x    = Rng.Z.gen ?g p in
  let ggx  = Z.(powm gg x p) in
  ({ x }, to_cstruct param ggx)

let shared ({ p; _ } as param) { x } cs =
  let ggy    = Numeric.Z.of_cstruct_be cs in
  let secret = Z.(powm ggy x p) in
  to_cstruct param secret

(* ... *)

let attempt bits =
  let p = gen_params bits in

  let (s1, m1) = gen_secret p
  and (s2, m2) = gen_secret p in

  let sh1 = shared p s1 m2
  and sh2 = shared p s2 m1 in

  assert (CS.cs_equal sh1 sh2);
  Cstruct.hexdump sh1