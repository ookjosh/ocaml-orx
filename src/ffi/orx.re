let (!@) = Ctypes.(!@);

let orx_error = (name: string) => {
  Fmt.invalid_arg("Fatal orx error in %s", name);
};

module Orx_gen = Orx_bindings.Bindings(Generated);

module Input = Orx_gen.Input;
module Resource = Orx_gen.Resource;
module Viewport = Orx_gen.Viewport;
module Display = Orx_gen.Display;

module Vector = {
  include Orx_gen.Vector;

  // Rotate about the z-axis
  let rotate = (v: t, angle: float): t => {
    let sin_angle = sin(angle);
    let cos_angle = cos(angle);
    {
      ...v,
      x: cos_angle *. v.x -. sin_angle *. v.y,
      y: sin_angle *. v.x +. cos_angle *. v.y,
    };
  };
};

module Physics = {
  include Orx_gen.Physics;

  let get_gravity = () => {
    let v: Vector.t = {x: 0.0, y: 0.0, z: 0.0};
    get_gravity(v);
  };
};

module Object = {
  include Orx_gen.Object;

  let get_world_position = (o: t): Vector.t => {
    let pos = Vector.allocate_raw();
    let pos' = get_world_position(o, pos);
    if (Ctypes.is_null(pos')) {
      orx_error("get_world_position");
    } else {
      Vector.of_raw(pos);
    };
  };

  let set_position = (o: t, v: Vector.t): unit => {
    switch (set_position(o, v)) {
    | Ok () => ()
    | Error () => orx_error("set_position")
    };
  };

  let set_text_string = (o: t, s: string): unit => {
    switch (set_text_string(o, s)) {
    | Ok () => ()
    | Error () => orx_error("set_text_string")
    };
  };
};

module Event = {
  include Orx_gen.Event;

  let event_handler = Ctypes.(t @-> returning(Orx_gen.Status.t));

  let add_handler =
    Ctypes.(
      Foreign.foreign(
        "orxEvent_AddHandler",
        Orx_types.Event_type.t
        @-> Foreign.funptr(event_handler)
        @-> returning(Orx_gen.Status.t),
      )
    );
};

module Clock = {
  include Orx_gen.Clock;

  let callback = Ctypes.(Info.t @-> ptr(void) @-> returning(void));

  let c_register =
    Ctypes.(
      Foreign.foreign(
        "orxClock_Register",
        t
        @-> Foreign.funptr(callback)
        @-> ptr(void)
        @-> Orx_types.Module_id.t
        @-> Orx_types.Clock_priority.t
        @-> returning(Orx_gen.Status.t),
      )
    );

  let register = (clock: t, callback, module_, priority) => {
    c_register(
      clock,
      (info, _ctx) => callback(info),
      Ctypes.null,
      module_,
      priority,
    );
  };
};

module Config = {
  include Orx_gen.Config;

  let bootstrap_function = Ctypes.(void @-> returning(Orx_gen.Status.t));

  let set_bootstrap =
    Ctypes.(
      Foreign.foreign(
        "orxConfig_SetBootstrap",
        Foreign.funptr(bootstrap_function) @-> returning(Orx_gen.Status.t),
      )
    );

  let set_list_string = (key: string, values: list(string)) => {
    let length = List.length(values);
    let c_values = Ctypes.CArray.of_list(Ctypes.string, values);
    set_list_string(key, Ctypes.CArray.start(c_values), length);
  };

  let append_list_string = (key: string, values: list(string)) => {
    let length = List.length(values);
    let c_values = Ctypes.CArray.of_list(Ctypes.string, values);
    append_list_string(key, Ctypes.CArray.start(c_values), length);
  };

  let get_vector = (key: string): Vector.t => {
    let vector: Vector.t = {x: 0.0, y: 0.0, z: 0.0};
    get_vector(key, vector);
  };

  let get_list_vector = (key: string, i: option(int)): Vector.t => {
    let vector: Vector.t = {x: 0.0, y: 0.0, z: 0.0};
    get_list_vector(key, i, vector);
  };

  let with_section = (section: string, f) => {
    switch (push_section(section)) {
    | Error () as e => e
    | Ok () =>
      let result = f();
      switch (pop_section()) {
      | Error () as e => e
      | Ok () => Ok(result)
      };
    };
  };

  let get =
      (get: string => 'a, ~section: string, ~key: string): result('a, 'err) => {
    with_section(section, () => get(key));
  };

  let get_list_item =
      (
        get: (string, option(int)) => 'a,
        i: option(int),
        ~section: string,
        ~key: string,
      )
      : result('a, 'error) => {
    with_section(section, () => get(key, i));
  };

  let get_list =
      (get: (string, option(int)) => 'a, ~section: string, ~key: string)
      : result(list('a), unit) => {
    let get_all = () => {
      let count = get_list_count(key);
      List.init(count, i => get(key, Some(i)));
    };
    with_section(section, get_all);
  };
};

module Main = {
  let init_function = Ctypes.(void @-> returning(Orx_gen.Status.t));
  let run_function = Ctypes.(void @-> returning(Orx_gen.Status.t));
  let exit_function = Ctypes.(void @-> returning(void));

  // This is wrapped differently because it's inlined in orx.h
  let execute_c = {
    Ctypes.(
      Foreign.foreign(
        "ml_orx_execute",
        int
        @-> ptr(string)
        @-> Foreign.funptr(init_function)
        @-> Foreign.funptr(run_function)
        @-> Foreign.funptr(exit_function)
        @-> returning(void),
      )
    );
  };

  let execute = (~init, ~run, ~exit, ()) => {
    let empty_argv = Ctypes.from_voidp(Ctypes.string, Ctypes.null);
    execute_c(0, empty_argv, init, run, exit);
  };
};