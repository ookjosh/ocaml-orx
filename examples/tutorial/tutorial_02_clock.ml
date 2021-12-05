(* Adaptation of the clock tutorial from Orx *)
(* This example is a direct adaptation of the 02_Clock.c tutorial from Orx *)

module State = struct
  module Clock_map = Map.Make (Orx.Clock)

  type t = Orx.Object.t Clock_map.t ref

  let state : t = ref Clock_map.empty

  let get () = !state

  let add (clock : Orx.Clock.t) (o : Orx.Object.t) : unit =
    state := Clock_map.add clock o !state
end

let update (clock_info : Orx.Clock.Info.t) =
  Orx.Config.push_section "Main";

  if Orx.Config.get_bool "DisplayLog" then
    Orx.Log.log "<%s>: Time = %.3f / DT = %.3f"
      (Orx.Clock.get_name (Orx.Clock.Info.get_clock clock_info |> Option.get))
      (Orx.Clock.Info.get_time clock_info)
      (Orx.Clock.Info.get_dt clock_info);

  Orx.Config.pop_section ();

  let clock = Orx.Clock.Info.get_clock clock_info |> Option.get in
  let obj = State.Clock_map.find clock (State.get ()) in
  Orx.Object.set_rotation obj (Float.pi *. Orx.Clock.Info.get_time clock_info)

let input_update (_clock_info : Orx.Clock.Info.t) =
  Orx.Config.push_section "Main";
  if Orx.Input.has_been_activated "Log" then
    Orx.Config.set_bool "DisplayLog" (not (Orx.Config.get_bool "DisplayLog"));
  Orx.Config.pop_section ();

  match Orx.Clock.get "Clock1" with
  | None -> ()
  | Some clock ->
    if Orx.Input.is_active "Faster" then
      Orx.Clock.set_modifier clock Multiply 4.0
    else if Orx.Input.is_active "Slower" then
      Orx.Clock.set_modifier clock Multiply 0.25
    else if Orx.Input.is_active "Normal" then
      Orx.Clock.set_modifier clock Multiply 0.0

let init () =
  let get_name (binding : string) : string =
    let (type_, id, mode) = Orx.Input.get_binding binding 0 |> Result.get_ok in
    Orx.Input.get_binding_name type_ id mode
  in
  Orx.Log.log
    ("@.- Press '%s' to toggle log display@."
    ^^ "- To stretch time for the first clock (updating the box):@."
    ^^ " . Press numpad '%s' to set it 4 times faster@."
    ^^ " . Press numpad '%s' to set it 4 times slower@."
    ^^ " . Press numpad '%s' to set it back to normal"
    )
    (get_name "Log") (get_name "Faster") (get_name "Slower") (get_name "Normal");

  let (_viewport : Orx.Viewport.t) =
    Orx.Viewport.create_from_config_exn "Viewport"
  in

  let object1 = Orx.Object.create_from_config_exn "Object1" in
  let object2 = Orx.Object.create_from_config_exn "Object2" in

  let clock1 = Orx.Clock.create_from_config_exn "Clock1" in
  let clock2 = Orx.Clock.create_from_config_exn "Clock2" in

  State.add clock1 object1;
  State.add clock2 object2;

  Orx.Clock.register clock1 update;
  Orx.Clock.register clock2 update;

  let main_clock = Orx.Clock.get_core () in
  Orx.Clock.register main_clock input_update;

  Ok ()

let run () =
  if Orx.Input.is_active "Quit" then
    Orx.Status.error
  else
    Orx.Status.ok

let () =
  Orx.Main.start ~config_dir:"examples/tutorial/data" ~init ~run "02_Clock"
