pragma solidity ^0.4.0;
import "./runtime.sol";
library pb_Rollup{
  //enum definition
              
  //struct definition
  struct Data {     
    bytes[] accounts;
    pb_Transaction.Data[] transactions;             
    //non serialized field for map
         
  }                           
  // Decoder section                       
  function decode(bytes bs) internal pure returns (Data) {
    (Data memory x,) = _decode(32, bs, bs.length);                       
    return x;                                                    
  }
  function decode(Data storage self, bytes bs) internal {
    (Data memory x,) = _decode(32, bs, bs.length);                    
    store(x, self);                                           
  }                             
  // innter decoder                       
  function _decode(uint p, bytes bs, uint sz)                   
      internal pure returns (Data, uint) {             
    Data memory r;                                          
    uint[3] memory counters;                                  
    uint fieldId;                                               
    _pb.WireType wireType;                                      
    uint bytesRead;                                             
    uint offset = p;                                            
    while(p < offset+sz) {                                     
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);  
      p += bytesRead;                                           
      if (false) {}
      else if(fieldId == 1)       
          p += _read_accounts(p, bs, nil(), counters);
      else if(fieldId == 2)       
          p += _read_transactions(p, bs, nil(), counters);
      else revert();                                              
    }                                                          
    p = offset;                                                 
    r.accounts = new bytes[](counters[1]);
    r.transactions = new pb_Transaction.Data[](counters[2]);
                                                    
    while(p < offset+sz) {                                     
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);  
      p += bytesRead;                                           
      if (false) {}
      else if(fieldId == 1)       
          p += _read_accounts(p, bs, r, counters);
      else if(fieldId == 2)       
          p += _read_transactions(p, bs, r, counters);
      else revert();                                             
    }                                                          
    return (r, sz);                                             
  }                                                            
                            
  // field readers                       
  function _read_accounts(uint p, bytes bs, Data r, uint[3] counters) internal pure returns (uint) {                            
    (bytes memory x, uint sz) = _pb._decode_bytes(p, bs);                   
    if(isNil(r)) {                                                  
      counters[1] += 1;                                            
    } else {                                                       
      r.accounts[ r.accounts.length - counters[1] ] = x;                                         
      if(counters[1] > 0) counters[1] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_transactions(uint p, bytes bs, Data r, uint[3] counters) internal pure returns (uint) {                            
    (pb_Transaction.Data memory x, uint sz) = _decode_Transaction(p, bs);                   
    if(isNil(r)) {                                                  
      counters[2] += 1;                                            
    } else {                                                       
      r.transactions[ r.transactions.length - counters[2] ] = x;                                         
      if(counters[2] > 0) counters[2] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
                            
  // struct decoder                       
  function _decode_Transaction(uint p, bytes bs)            
      internal pure returns (pb_Transaction.Data, uint) {    
    (uint sz, uint bytesRead) = _pb._decode_varint(p, bs);   
    p += bytesRead;                                    
    (pb_Transaction.Data memory r,) = pb_Transaction._decode(p, bs, sz);               
    return (r, sz + bytesRead);                        
  }      
                                      
  // Encoder section                 
  function encode(Data r) internal pure returns (bytes) {
    bytes memory bs = new bytes(_estimate(r));					   
    uint sz = _encode(r, 32, bs);                                 
    assembly { mstore(bs, sz) }                                 
    return bs;                                                    
  }                                                              
                     
  // inner encoder                  
  function _encode(Data r, uint p, bytes bs)        
      internal pure returns (uint) {               
    uint offset = p;                                   
uint i;
    for(i=0; i<r.accounts.length; i++) {               
      p += _pb._encode_key(1, _pb.WireType.LengthDelim, p, bs); 
      p += _pb._encode_bytes(r.accounts[i], p, bs);             
    }                                                 
    for(i=0; i<r.transactions.length; i++) {               
      p += _pb._encode_key(2, _pb.WireType.LengthDelim, p, bs); 
      p += pb_Transaction._encode_nested(r.transactions[i], p, bs);             
    }                                                 

    return p - offset;                                 
  }                                                    
                    
  // nested encoder                 
  function _encode_nested(Data r, uint p, bytes bs)        
      internal pure returns (uint) {                       
    uint offset = p;                                           
    p += _pb._encode_varint(_estimate(r), p, bs);              
    p += _encode(r, p, bs);                                    
    return p - offset;                                         
  }                                                            
                   
  // estimator                 
  function _estimate(Data r) internal pure returns (uint) { 
    uint e;                                                        
uint i;
    for(i=0; i<r.accounts.length; i++) e+= 1 + _pb._sz_lendelim(r.accounts[i].length); 
    for(i=0; i<r.transactions.length; i++) e+= 1 + _pb._sz_lendelim(pb_Transaction._estimate(r.transactions[i])); 

    return e;                                                      
  }                                                                
                        
            
  //store function                                                     
  function store(Data memory input, Data storage output) internal{
    output.accounts = input.accounts;                           
    output.transactions.length = input.transactions.length;             
    for(uint i2=0; i2<input.transactions.length; i2++) {    
      pb_Transaction.store(input.transactions[i2], output.transactions[i2]); 
          }
  }                                                                   
             
                 
  //utility functions                                           
  function nil() internal pure returns (Data r) {        
    assembly { r := 0 }                                       
  }                                                            
  function isNil(Data x) internal pure returns (bool r) {
    assembly { r := iszero(x) }                               
  }                                                            
} //library pb_Rollup

library pb_Transaction{
  //enum definition
              
  //struct definition
  struct Data {     
    int32 from;
    int32 to;
    int64 value;             
    //non serialized field for map
         
  }                           
  // Decoder section                       
  function decode(bytes bs) internal pure returns (Data) {
    (Data memory x,) = _decode(32, bs, bs.length);                       
    return x;                                                    
  }
  function decode(Data storage self, bytes bs) internal {
    (Data memory x,) = _decode(32, bs, bs.length);                    
    store(x, self);                                           
  }                             
  // innter decoder                       
  function _decode(uint p, bytes bs, uint sz)                   
      internal pure returns (Data, uint) {             
    Data memory r;                                          
    uint[4] memory counters;                                  
    uint fieldId;                                               
    _pb.WireType wireType;                                      
    uint bytesRead;                                             
    uint offset = p;                                            
    while(p < offset+sz) {                                     
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);  
      p += bytesRead;                                           
      if (false) {}
      else if(fieldId == 1)       
          p += _read_from(p, bs, r, counters);
      else if(fieldId == 2)       
          p += _read_to(p, bs, r, counters);
      else if(fieldId == 3)       
          p += _read_value(p, bs, r, counters);
      else revert();                                              
    }                                                          
    p = offset;                                                 
                                                    
    while(p < offset+sz) {                                     
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);  
      p += bytesRead;                                           
      if (false) {}
      else if(fieldId == 1)       
          p += _read_from(p, bs, nil(), counters);
      else if(fieldId == 2)       
          p += _read_to(p, bs, nil(), counters);
      else if(fieldId == 3)       
          p += _read_value(p, bs, nil(), counters);
      else revert();                                             
    }                                                          
    return (r, sz);                                             
  }                                                            
                            
  // field readers                       
  function _read_from(uint p, bytes bs, Data r, uint[4] counters) internal pure returns (uint) {                            
    (int32 x, uint sz) = _pb._decode_int32(p, bs);                   
    if(isNil(r)) {                                                  
      counters[1] += 1;                                            
    } else {                                                       
      r.from = x;                                         
      if(counters[1] > 0) counters[1] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_to(uint p, bytes bs, Data r, uint[4] counters) internal pure returns (uint) {                            
    (int32 x, uint sz) = _pb._decode_int32(p, bs);                   
    if(isNil(r)) {                                                  
      counters[2] += 1;                                            
    } else {                                                       
      r.to = x;                                         
      if(counters[2] > 0) counters[2] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_value(uint p, bytes bs, Data r, uint[4] counters) internal pure returns (uint) {                            
    (int64 x, uint sz) = _pb._decode_int64(p, bs);                   
    if(isNil(r)) {                                                  
      counters[3] += 1;                                            
    } else {                                                       
      r.value = x;                                         
      if(counters[3] > 0) counters[3] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
                            
  // struct decoder                       
                                      
  // Encoder section                 
  function encode(Data r) internal pure returns (bytes) {
    bytes memory bs = new bytes(_estimate(r));					   
    uint sz = _encode(r, 32, bs);                                 
    assembly { mstore(bs, sz) }                                 
    return bs;                                                    
  }                                                              
                     
  // inner encoder                  
  function _encode(Data r, uint p, bytes bs)        
      internal pure returns (uint) {               
    uint offset = p;                                   

    p += _pb._encode_key(1, _pb.WireType.Varint, p, bs);     
    p += _pb._encode_int32(r.from, p, bs);                   
    p += _pb._encode_key(2, _pb.WireType.Varint, p, bs);     
    p += _pb._encode_int32(r.to, p, bs);                   
    p += _pb._encode_key(3, _pb.WireType.Varint, p, bs);     
    p += _pb._encode_int64(r.value, p, bs);                   

    return p - offset;                                 
  }                                                    
                    
  // nested encoder                 
  function _encode_nested(Data r, uint p, bytes bs)        
      internal pure returns (uint) {                       
    uint offset = p;                                           
    p += _pb._encode_varint(_estimate(r), p, bs);              
    p += _encode(r, p, bs);                                    
    return p - offset;                                         
  }                                                            
                   
  // estimator                 
  function _estimate(Data r) internal pure returns (uint) { 
    uint e;                                                        

    e += 1 + _pb._sz_int32(r.from); 
    e += 1 + _pb._sz_int32(r.to); 
    e += 1 + _pb._sz_int64(r.value); 

    return e;                                                      
  }                                                                
                        
            
  //store function                                                     
  function store(Data memory input, Data storage output) internal{
    output.from = input.from;                           
    output.to = input.to;                           
    output.value = input.value;                           

  }                                                                   
             
                 
  //utility functions                                           
  function nil() internal pure returns (Data r) {        
    assembly { r := 0 }                                       
  }                                                            
  function isNil(Data x) internal pure returns (bool r) {
    assembly { r := iszero(x) }                               
  }                                                            
} //library pb_Transaction

library pb_BlockHeader{
  //enum definition
              
  //struct definition
  struct Data {     
    bytes hash;
    bytes parentHash;
    bytes qcHash;
    bytes dataHash;
    bytes txHash;
    bytes stateHash;
    int32 height;
    int64 timestamp;             
    //non serialized field for map
         
  }                           
  // Decoder section                       
  function decode(bytes bs) internal pure returns (Data) {
    (Data memory x,) = _decode(32, bs, bs.length);                       
    return x;                                                    
  }
  function decode(Data storage self, bytes bs) internal {
    (Data memory x,) = _decode(32, bs, bs.length);                    
    store(x, self);                                           
  }                             
  // innter decoder                       
  function _decode(uint p, bytes bs, uint sz)                   
      internal pure returns (Data, uint) {             
    Data memory r;                                          
    uint[9] memory counters;                                  
    uint fieldId;                                               
    _pb.WireType wireType;                                      
    uint bytesRead;                                             
    uint offset = p;                                            
    while(p < offset+sz) {                                     
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);  
      p += bytesRead;                                           
      if (false) {}
      else if(fieldId == 1)       
          p += _read_hash(p, bs, r, counters);
      else if(fieldId == 2)       
          p += _read_parentHash(p, bs, r, counters);
      else if(fieldId == 3)       
          p += _read_qcHash(p, bs, r, counters);
      else if(fieldId == 4)       
          p += _read_dataHash(p, bs, r, counters);
      else if(fieldId == 5)       
          p += _read_txHash(p, bs, r, counters);
      else if(fieldId == 6)       
          p += _read_stateHash(p, bs, r, counters);
      else if(fieldId == 7)       
          p += _read_height(p, bs, r, counters);
      else if(fieldId == 8)       
          p += _read_timestamp(p, bs, r, counters);
      else revert();                                              
    }                                                          
    p = offset;                                                 
                                                    
    while(p < offset+sz) {                                     
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);  
      p += bytesRead;                                           
      if (false) {}
      else if(fieldId == 1)       
          p += _read_hash(p, bs, nil(), counters);
      else if(fieldId == 2)       
          p += _read_parentHash(p, bs, nil(), counters);
      else if(fieldId == 3)       
          p += _read_qcHash(p, bs, nil(), counters);
      else if(fieldId == 4)       
          p += _read_dataHash(p, bs, nil(), counters);
      else if(fieldId == 5)       
          p += _read_txHash(p, bs, nil(), counters);
      else if(fieldId == 6)       
          p += _read_stateHash(p, bs, nil(), counters);
      else if(fieldId == 7)       
          p += _read_height(p, bs, nil(), counters);
      else if(fieldId == 8)       
          p += _read_timestamp(p, bs, nil(), counters);
      else revert();                                             
    }                                                          
    return (r, sz);                                             
  }                                                            
                            
  // field readers                       
  function _read_hash(uint p, bytes bs, Data r, uint[9] counters) internal pure returns (uint) {                            
    (bytes memory x, uint sz) = _pb._decode_bytes(p, bs);                   
    if(isNil(r)) {                                                  
      counters[1] += 1;                                            
    } else {                                                       
      r.hash = x;                                         
      if(counters[1] > 0) counters[1] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_parentHash(uint p, bytes bs, Data r, uint[9] counters) internal pure returns (uint) {                            
    (bytes memory x, uint sz) = _pb._decode_bytes(p, bs);                   
    if(isNil(r)) {                                                  
      counters[2] += 1;                                            
    } else {                                                       
      r.parentHash = x;                                         
      if(counters[2] > 0) counters[2] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_qcHash(uint p, bytes bs, Data r, uint[9] counters) internal pure returns (uint) {                            
    (bytes memory x, uint sz) = _pb._decode_bytes(p, bs);                   
    if(isNil(r)) {                                                  
      counters[3] += 1;                                            
    } else {                                                       
      r.qcHash = x;                                         
      if(counters[3] > 0) counters[3] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_dataHash(uint p, bytes bs, Data r, uint[9] counters) internal pure returns (uint) {                            
    (bytes memory x, uint sz) = _pb._decode_bytes(p, bs);                   
    if(isNil(r)) {                                                  
      counters[4] += 1;                                            
    } else {                                                       
      r.dataHash = x;                                         
      if(counters[4] > 0) counters[4] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_txHash(uint p, bytes bs, Data r, uint[9] counters) internal pure returns (uint) {                            
    (bytes memory x, uint sz) = _pb._decode_bytes(p, bs);                   
    if(isNil(r)) {                                                  
      counters[5] += 1;                                            
    } else {                                                       
      r.txHash = x;                                         
      if(counters[5] > 0) counters[5] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_stateHash(uint p, bytes bs, Data r, uint[9] counters) internal pure returns (uint) {                            
    (bytes memory x, uint sz) = _pb._decode_bytes(p, bs);                   
    if(isNil(r)) {                                                  
      counters[6] += 1;                                            
    } else {                                                       
      r.stateHash = x;                                         
      if(counters[6] > 0) counters[6] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_height(uint p, bytes bs, Data r, uint[9] counters) internal pure returns (uint) {                            
    (int32 x, uint sz) = _pb._decode_int32(p, bs);                   
    if(isNil(r)) {                                                  
      counters[7] += 1;                                            
    } else {                                                       
      r.height = x;                                         
      if(counters[7] > 0) counters[7] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
  function _read_timestamp(uint p, bytes bs, Data r, uint[9] counters) internal pure returns (uint) {                            
    (int64 x, uint sz) = _pb._decode_int64(p, bs);                   
    if(isNil(r)) {                                                  
      counters[8] += 1;                                            
    } else {                                                       
      r.timestamp = x;                                         
      if(counters[8] > 0) counters[8] -= 1;                      
    }                                                               
    return sz;                                                       
  }                                                                 
                            
  // struct decoder                       
                                      
  // Encoder section                 
  function encode(Data r) internal pure returns (bytes) {
    bytes memory bs = new bytes(_estimate(r));					   
    uint sz = _encode(r, 32, bs);                                 
    assembly { mstore(bs, sz) }                                 
    return bs;                                                    
  }                                                              
                     
  // inner encoder                  
  function _encode(Data r, uint p, bytes bs)        
      internal pure returns (uint) {               
    uint offset = p;                                   

    p += _pb._encode_key(1, _pb.WireType.LengthDelim, p, bs);     
    p += _pb._encode_bytes(r.hash, p, bs);                   
    p += _pb._encode_key(2, _pb.WireType.LengthDelim, p, bs);     
    p += _pb._encode_bytes(r.parentHash, p, bs);                   
    p += _pb._encode_key(3, _pb.WireType.LengthDelim, p, bs);     
    p += _pb._encode_bytes(r.qcHash, p, bs);                   
    p += _pb._encode_key(4, _pb.WireType.LengthDelim, p, bs);     
    p += _pb._encode_bytes(r.dataHash, p, bs);                   
    p += _pb._encode_key(5, _pb.WireType.LengthDelim, p, bs);     
    p += _pb._encode_bytes(r.txHash, p, bs);                   
    p += _pb._encode_key(6, _pb.WireType.LengthDelim, p, bs);     
    p += _pb._encode_bytes(r.stateHash, p, bs);                   
    p += _pb._encode_key(7, _pb.WireType.Varint, p, bs);     
    p += _pb._encode_int32(r.height, p, bs);                   
    p += _pb._encode_key(8, _pb.WireType.Varint, p, bs);     
    p += _pb._encode_int64(r.timestamp, p, bs);                   

    return p - offset;                                 
  }                                                    
                    
  // nested encoder                 
  function _encode_nested(Data r, uint p, bytes bs)        
      internal pure returns (uint) {                       
    uint offset = p;                                           
    p += _pb._encode_varint(_estimate(r), p, bs);              
    p += _encode(r, p, bs);                                    
    return p - offset;                                         
  }                                                            
                   
  // estimator                 
  function _estimate(Data r) internal pure returns (uint) { 
    uint e;                                                        

    e += 1 + _pb._sz_lendelim(r.hash.length); 
    e += 1 + _pb._sz_lendelim(r.parentHash.length); 
    e += 1 + _pb._sz_lendelim(r.qcHash.length); 
    e += 1 + _pb._sz_lendelim(r.dataHash.length); 
    e += 1 + _pb._sz_lendelim(r.txHash.length); 
    e += 1 + _pb._sz_lendelim(r.stateHash.length); 
    e += 1 + _pb._sz_int32(r.height); 
    e += 1 + _pb._sz_int64(r.timestamp); 

    return e;                                                      
  }                                                                
                        
            
  //store function                                                     
  function store(Data memory input, Data storage output) internal{
    output.hash = input.hash;                           
    output.parentHash = input.parentHash;                           
    output.qcHash = input.qcHash;                           
    output.dataHash = input.dataHash;                           
    output.txHash = input.txHash;                           
    output.stateHash = input.stateHash;                           
    output.height = input.height;                           
    output.timestamp = input.timestamp;                           

  }                                                                   
             
                 
  //utility functions                                           
  function nil() internal pure returns (Data r) {        
    assembly { r := 0 }                                       
  }                                                            
  function isNil(Data x) internal pure returns (bool r) {
    assembly { r := iszero(x) }                               
  }                                                            
} //library pb_BlockHeader
