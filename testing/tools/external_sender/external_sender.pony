"""
A tool for test sending external messages.
"""
use "buffered"
use "net"
use "files"
use "sendence/bytes"
use "sendence/messages"
use "sendence/options"

actor Main
  new create(env: Env) =>
    try
      var x_host: String = ""
      var x_service: String = "0"
      var message: String = "DEFAULT MESSAGE"
      let options = Options(env.args)

      options
        .add("external", "e", StringArgument)
        .add("message", "m", StringArgument)
        .add("help", "h", None)

        for option in options do
          match option
          | ("external", let arg: String) =>
            let x_addr = arg.split(":")
            x_host = x_addr(0)
            x_service = x_addr(1)
          | ("message", let arg: String) => message = arg
          | ("help", None) =>
            @printf[I32](
              """
              PARAMETERS:
              -----------------------------------------------------------------------------------
              --external/-e [Specifies address to send message to]
              --message/-m [Specifies message to send]
              -----------------------------------------------------------------------------------
              """.cstring())
            return
          end
        end

      let auth = env.root as AmbientAuth

      let msg = ExternalMsgEncoder.print_message(message)
      let tcp_auth = TCPConnectAuth(auth)
      let conn = TCPConnection(tcp_auth, ExternalSenderConnectNotifier(auth,
        msg), x_host, x_service)
    else
      @printf[I32]("Error sending.\n".cstring())
    end


class ExternalSenderConnectNotifier is TCPConnectionNotify
  let _auth: AmbientAuth
  let _msg: Array[ByteSeq] val

  new iso create(auth: AmbientAuth, msg: Array[ByteSeq] val)
  =>
    _auth = auth
    _msg = msg

  fun ref connected(conn: TCPConnection ref) =>
    @printf[I32]("Connected...\n".cstring())
    conn.writev(_msg)
    @printf[I32]("Sent message!\n".cstring())

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso,
    n: USize): Bool
  =>
    true