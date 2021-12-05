(* Adaptation of the scrolling tutorial from Orx *)
(* This example is a direct adaptation of the 09_Scrolling.c tutorial from Orx *)

module State = struct
  type t = Orx.Camera.t

  let state : t option ref = ref None

  let get () = Option.get !state
end

let update (clock_info : Orx.Clock.Info.t) =
  let camera = State.get () in

  Orx.Config.push_section "Tutorial";
  let scroll_speed = Orx.Config.get_vector "ScrollSpeed" in
  Orx.Config.pop_section ();

  let scroll_speed =
    Orx.Vector.mulf scroll_speed (Orx.Clock.Info.get_dt clock_info)
  in

  let move_x =
    if Orx.Input.is_active "CameraRight" then
      Orx.Vector.get_x scroll_speed
    else if Orx.Input.is_active "CameraLeft" then
      -.Orx.Vector.get_x scroll_speed
    else
      0.0
  in
  let move_y =
    if Orx.Input.is_active "CameraUp" then
      -.Orx.Vector.get_y scroll_speed
    else if Orx.Input.is_active "CameraDown" then
      Orx.Vector.get_y scroll_speed
    else
      0.0
  in
  let move_z =
    if Orx.Input.is_active "CameraZoomIn" then
      Orx.Vector.get_z scroll_speed
    else if Orx.Input.is_active "CameraZoomOut" then
      -.Orx.Vector.get_z scroll_speed
    else
      0.0
  in
  let move = Orx.Vector.make ~x:move_x ~y:move_y ~z:move_z in

  let camera_position = Orx.Camera.get_position camera in
  Orx.Camera.set_position camera (Orx.Vector.add camera_position move)

let init () =
  (* Print out a hint to the user about what's to come *)
  let get_name (binding : string) : string =
    let (type_, id, mode) = Orx.Input.get_binding binding 0 |> Result.get_ok in
    Orx.Input.get_binding_name type_ id mode
  in

  Orx.Log.log
    ("@.- '%s', '%s', '%s' & '%s' will move the camera@."
    ^^ "- '%s' & '%s' will zoom in/out@."
    ^^ "* The scrolling and auto-scaling of objects is data-driven, no code \
        required@."
    ^^ "* The sky background will follow the camera (parent/child frame \
        relation)"
    )
    (get_name "CameraUp") (get_name "CameraLeft") (get_name "CameraDown")
    (get_name "CameraRight") (get_name "CameraZoomIn") (get_name "CameraZoomOut");

  let viewport = Orx.Viewport.create_from_config_exn "Viewport" in
  let camera = Orx.Viewport.get_camera viewport |> Option.get in
  State.state := Some camera;

  let clock = Orx.Clock.get_core () in
  Orx.Clock.register clock update;

  let _scene : Orx.Object.t = Orx.Object.create_from_config_exn "Scene" in

  Ok ()

let run () =
  if Orx.Input.is_active "Quit" then
    Orx.Status.error
  else
    Orx.Status.ok

let () =
  Orx.Main.start ~config_dir:"examples/tutorial/data" ~init ~run "09_Scrolling"
