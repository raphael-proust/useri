(*---------------------------------------------------------------------------
   Copyright (c) 2014 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

open Gg
open React

let log  fmt = Format.printf  (fmt ^^ "@\n%!")
let warn fmt = Format.eprintf ("Useri: " ^^ fmt ^^ "@.") 
let warn_time () = warn "performance.now () missing, using Date.now ()"  
let warn_drag () = warn "Drag.file event not supported" 

module Ev = struct
  let ids = ref [] 
  let release () = List.iter Dom.removeEventListener !ids

  let cb node e f =
    let h = Dom.full_handler (fun n ev -> Js.bool (f n ev)) in
    ids := Dom.addEventListener node e h (Js.bool false) :: !ids; 
    ()
end

module Mouse = struct
  let pos : p2 signal = fst (S.create P2.o)
  let dpos : v2 event = fst (E.create ())
  let left : bool signal = fst (S.create false)
  let left_down : p2 event = fst (E.create ())
  let left_up : p2 event = fst (E.create ())
  let middle : bool signal = fst (S.create false)
  let middle_down : p2 event = fst (E.create ())
  let middle_up : p2 event = fst (E.create ())
  let right : bool signal = fst (S.create false)
  let right_up : p2 event = fst (E.create ())
  let right_down : p2 event = fst (E.create ())
end

module Key = struct
  include Useri_backend_base.Key 

  let any_down : sym event = fst (E.create ())
  let any_repeat : sym event = fst (E.create ())
  let any_up : sym event = fst (E.create ())
  let any_holds : bool signal = fst (S.create false)
  let down : ?repeat:bool -> sym -> unit event = 
    fun ?(repeat = false) sym -> failwith "TODO"

  let up : sym -> unit event = fun sym -> failwith "TODO"
  let holds : sym -> bool signal = fun sym -> failwith "TODO"
  let meta : bool signal = fst (S.create false)
  let ctrl : bool signal = fst (S.create false) 
  let alt : bool signal = fst (S.create false)
end

module Text = struct 
  let input_enabled : bool signal = fst (S.create false)
  let set_input_enabled : bool -> unit = fun _ -> ()
  let input : string event = fst (E.create ())
  let editing : (string * int * int) event = fst (E.create ())
  let clipboard : string option signal = fst (S.create None)
  let set_clipboard : string option -> unit = fun s -> failwith "TODO"
end

module Drop = struct

  type file_ready_error = unit
  let file, send_file = E.create ()
  let file_ready, send_file_ready = E.create () 

  let read_file f = 
    let r = jsnew File.fileReader () in 
    let name = Js.to_string (f ## name) in
    let onload _ = 
      let content = 
        match Js.Opt.to_option (File.CoerceTo.string (r ## result)) with 
        | None -> assert false 
        | Some str -> Js.to_string str
      in
      Sys_js.register_file ~name ~content;
      send_file_ready (`Ok name); 
      Js._false
    in
    let onerror _ = send_file_ready (`Error (name, ())); Js._false in
    r ## onload <- Dom.handler onload;
    r ## onerror <- Dom.handler onerror;
    r ## readAsBinaryString (f);
    ()

  let drop _ e = 
    Dom.preventDefault e;
    let files = e ## dataTransfer ## files in 
    for i = 0 to files ## length - 1 do 
      match Js.Opt.to_option (files ## item(i)) with 
      | None -> assert false 
      | Some file -> send_file (Js.to_string (file ## name)); read_file file
    done;
    false

  let dd_support () = 
    let d = Dom_html.(createDiv document) in 
    Js.Optdef.test ((Js.Unsafe.coerce d) ## ondragenter) && 
    Js.Optdef.test ((Js.Unsafe.coerce d) ## ondragover) &&
    Js.Optdef.test ((Js.Unsafe.coerce d) ## ondrop)
    
  let init () = 
    if not (dd_support ()) then warn_drag () else
    let stop _ e = Dom.preventDefault e; false in
    Ev.cb Dom_html.window Dom_html.Event.dragenter stop; 
    Ev.cb Dom_html.window Dom_html.Event.dragover stop;
    Ev.cb Dom_html.window Dom_html.Event.drop drop

end

module Time = struct

  (* Time span *) 

  type span = Useri_backend_base.Time.span 

  (* Passing time *) 

  let tick_now = 
    let date_now () = (jsnew Js.date_now () ## getTime ()) /. 1000. in
    let perf_now () = 
      (Js.Unsafe.coerce Dom_html.window) ## performance ## now () /. 1000. 
    in
    let perf = (Js.Unsafe.coerce Dom_html.window) ## performance in 
    match Js.Optdef.to_option perf with 
    | None -> warn_time (); date_now 
    | Some p ->
        match (Js.Unsafe.coerce p) ## now with
        | None -> warn_time (); date_now 
        | Some n -> perf_now

  let start = tick_now ()
  let elapsed () = tick_now () -. start 
  let tick span = 
    let e, send_e = E.create () in 
    let start = tick_now () in
    let action () = send_e (tick_now () -. start) in 
    let ms = span *. 1000. in 
    ignore (Dom_html.window ## setTimeout (Js.wrap_callback action, ms)); 
    e
    
  (* Counting time *) 
    
  type counter = span 
  let counter () = tick_now () 
  let value c = tick_now () -. c 

  (* Pretty printing time *)
                
  let pp_s = Useri_backend_base.Time.pp_s
  let pp_ms = Useri_backend_base.Time.pp_ms
  let pp_mus = Useri_backend_base.Time.pp_mus
end

module Human = struct
  include Useri_backend_base.Human

  let feel : unit -> [ `Interacting | `Interrupted | `Left ] signal = 
    fun () -> failwith "TODO"
end

module Surface = struct

  let size : size2 signal = fst (S.create Size2.zero)
  let update : unit -> unit = fun () -> failwith "TODO"
  let refresh : float event = fst (E.create ())
  let request_refresh : unit -> unit = fun () -> failwith "TODO"
  let set_refresher : 'a event -> unit = fun e -> failwith "TODO"
  let steady_refresh : until:'a event -> unit = fun ~until -> failwith "TODO"
  let animate : span:float -> float signal = fun ~span -> failwith "TODO"
  let refresh_hz : int signal = fst (S.create 60)
  let set_refresh_hz : int -> unit = fun hz -> ()

  type colors = [ `RGBA_8888 | `RGB_565 ]
  type depth = [ `D_24 | `D_16 ]
  type stencil = [ `S_8 ]
  type spec = unit

  let spec 
      ?share
      ?accelerated
      ?multisample
      ?doublebuffer
      ?stereo
      ?srgb
      ?colors
      ?depth
      ?stencil
      ~gl:(min, maj) () = ()
                    

end

module App = struct

  let prefs_path ~org ~app = failwith "TODO"
  let size : size2 signal = fst (S.create Size2.zero)
  let pos : p2 signal = fst (S.create P2.o)
  let env key ~default parse = failwith "TODO"

  type mode = Useri_backend_base.App.mode 
  let mode_switch ?(init = `Windowed) e =
    let switch_mode = function 
    | `Windowed -> `Fullscreen 
    | `Fullscreen -> `Windowed 
    in
    S.accum (E.map (fun _ m -> switch_mode m) e) init

  let mode_sig, set_mode_sig = S.create (S.const `Windowed)
  let (mode : mode signal) = S.switch ~eq:( == ) mode_sig

  let quit, send_quit = E.create ()

  (* Event and signal sinks *) 

  type sink = Esink : 'a event -> sink | Ssink : 'a signal -> sink 
  let sinks = ref []
  let sink_event e = sinks := Esink e :: !sinks
  let sink_signal s = sinks := Ssink s :: !sinks
  let release_sinks () = 
    let release = function 
    | Esink e -> E.stop ~strong:true e 
    | Ssink s -> S.stop ~strong:true s
    in
    List.iter release !sinks; sinks := []

  (* Init, run and release *)

  let init () = 
    let send_quit _ _ = send_quit (); false in
    Ev.cb Dom_html.window Dom_html.Event.unload send_quit; 
    Drop.init ();
    ()

  let start, send_start = E.create ()
  let stop, send_stop = E.create ()
  let running = ref false
  let send_start ?step () = 
    if not !running then (running := true; send_start ?step ()) 

  let send_stop () = send_stop (); running := false

  let init ?hidpi ?pos ?size ?name ?surface ?mode () = 
    let step = React.Step.create () in
    init ();
    send_start ~step ();
    React.Step.execute step;
    `Ok ()

  let run_step () = send_start (); max_float
  let run ?(until = E.never) () = send_start ()
  let release ?(sinks = true) () =
    send_stop ();
    if sinks then release_sinks ();
    Ev.release ();
    ()

  (* Launch context *) 

  type launch_context = Useri_backend_base.App.launch_context
  let launch_context = `Browser
  let pp_launch_context = Useri_backend_base.App.pp_launch_context
    
  (* Platform and backend *)

  let platform = Js.to_string (Dom_html.window ## navigator ## platform)
  
  type backend = Useri_backend_base.App.backend 
  let backend = `Jsoo
  let pp_backend = Useri_backend_base.App.pp_backend
  
  type backend_scheme = Useri_backend_base.App.backend_scheme 
  let backend_scheme = `Async
  let pp_backend_scheme = Useri_backend_base.App.pp_backend_scheme 

  (* CPU count *) 

  type cpu_count = Useri_backend_base.App.cpu_count 
  let cpu_count = 
    let n = Dom_html.window ## navigator in
    match Js.Optdef.to_option ((Js.Unsafe.coerce n) ## hardwareConcurrency)
    with None -> `Unknown | Some c -> `Known c

  let pp_cpu_count = Useri_backend_base.App.pp_cpu_count 

end

(*---------------------------------------------------------------------------
   Copyright (c) 2014 Daniel C. Bünzli.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:
     
   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

   3. Neither the name of Daniel C. Bünzli nor the names of
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ---------------------------------------------------------------------------*)
