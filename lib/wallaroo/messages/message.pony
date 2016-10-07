use "collections"
use "wallaroo/topology"


class MsgEnvelope
  let origin_tag: Step tag // tag referencing upstream origin for msg
  let msg_uid: U64         // Source assigned UID; universally unique
  let seq_id: U64          // assigned by immediate upstream origin
  let route_id: U64        // assigned by immediate upstream origin

  new val create(origin_tag': Step tag, seq_id': U64, route_id': U64)
  =>
    origin_tag = origin_tag'
    seq_id = seq_id'
    route_id = route_id'

class HighWaterMarkTable
  """
  Keep track of a high watermark for each message coming into a step.
  We store the seq_id as assigned to a message by the upstream origin
  that sent the message.
  """
  let _hwmt: HashMap[(U64, U64), U64]  // tuple access to high watermark
  
  fun ref updateHighWatermark(origin_tag: U64, route_id: U64, seq_id: U64)
  =>
    _hwmt.upsert((origin_tag, route_id), seq_id)
    

class TranslationTable
  """
  We need to be able to go from an incoming seq_id to an outgoing seq_id and
  vice versa.
  Create a new entry every time we send a message downstream.
  Remove old entries every time we receive a new low watermark.
  """
  let _inToOut: HashMap[U64, U64]
  let _outToIn: HashMap[U64, U64]

  fun ref update(in_seq_id: U64, out_seq_id: U64)
  =>
    _inToOut.upsert(in_seq_id, out_seq_id)
    _outToIn.upsert(out_seq_id, in_seq_id)
    
  fun outToIn(out_seq_id: U64): U64
  =>
    _tt(out_seq_id)

  fun ref remove(in_seq_id: U64)
  =>
    _tt.remove(in_seq_id)


class LowWaterMarkTable
  """
  Keep track of low watermark values per route as reported by downstream steps.
  """
  let _lwmt: HashMap[U64, U64]

  fun ref updateLowWatermark(route_id: U64, seq_id: U64)
  =>
    _lwmt.upsert(route_id, seq_id)

    
