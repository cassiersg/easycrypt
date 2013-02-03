(* -------------------------------------------------------------------- *)
open EcUtils
open EcMaps
open EcSymbols

(* -------------------------------------------------------------------- *)
type path =
  | Pident of EcIdent.t
  | Pqname of path * EcIdent.t

type xpath = path * xpath list

let rec p_equal p1 p2 = 
  p1 == p2 || match p1, p2 with
  | Pident id1, Pident id2 -> EcIdent.id_equal id1 id2
  | Pqname (p1,id1), Pqname(p2,id2) -> 
      EcIdent.id_equal id1 id2 && p_equal p1 p2
  | _, _ -> false

let rec p_compare p1 p2 =
  if p1 == p2 then 0
  else match p1, p2 with
  | Pident id1, Pident id2 -> EcIdent.id_compare id1 id2
  | Pident _, _ -> -1
  | Pqname(p1, id1), Pqname(p2,id2) ->
      let cmp = EcIdent.id_compare id1 id2 in
      if cmp = 0 then p_compare p1 p2 else cmp
  | _, Pident _ -> 1

(* -------------------------------------------------------------------- *)
let rec p_equal_complex ((p1, args1) : xpath) ((p2, args2) : xpath) =
     (p_equal p1 p2)
  && (List.length args1 = List.length args2)
  && (List.for_all2 p_equal_complex args1 args2)

(* -------------------------------------------------------------------- *)
(* TODO : Remove this function *)
let rec create (path : string) =
  match try_nf (fun () -> String.rindex path '.') with
    | None   -> Pident (EcIdent.create path)
    | Some i ->
      let path = String.sub path 0 i
      and name = String.sub path (i+1) (String.length path - (i+1)) in
        Pqname (create path, EcIdent.create name)

(* -------------------------------------------------------------------- *)
let tolist =
  let rec aux l = function
    | Pident x      -> x :: l
    | Pqname (p, x) -> aux (x :: l) p in
  aux []

(* -------------------------------------------------------------------- *)
let rec tostring p =
  match p with
  | Pident x ->
      Printf.sprintf "[%s]" (EcIdent.tostring x)
  | Pqname (p, x) ->
      Printf.sprintf "%s.%s" (tostring p) (tostring (Pident x))

(* -------------------------------------------------------------------- *)
let toqsymbol (p : path) =
  match p with
  | Pident x      -> ([], EcIdent.name x)
  | Pqname (p, x) ->
    let scope = tolist p in
      (List.map EcIdent.name scope, EcIdent.name x)

(* -------------------------------------------------------------------- *)
let basename = function
  | Pident x -> x
  | Pqname (_, x) -> x

(* -------------------------------------------------------------------- *)
let rec rootname = function
  | Pident x -> x
  | Pqname (p, _) -> rootname p

(* -------------------------------------------------------------------- *)
let extend (p : path option) (x : EcIdent.t) =
  match p with
  | None   -> Pident x
  | Some p -> Pqname (p, x)

(* -------------------------------------------------------------------- *)
let rec concat p1 p2 = 
  match p2 with
  | Pident x -> Pqname(p1, x)
  | Pqname (p2,x) -> Pqname(concat p1 p2, x)


(* -------------------------------------------------------------------- *)
module PathComparable = struct
  type t = path
  let compare = p_compare
end

module Mp = Map.Make(PathComparable)
module Sp = Mp.Set
