## # sdl/net
##
## Network communication using TCP and UDP sockets
##
## This module provides cross-platform networking capabilities through the SDL_net library.
## It supports both reliable TCP connections and fast UDP datagrams for multiplayer games.
##
## ## SDL 1.2 Reference
##
## SDL_net extends SDL 1.2 with socket-based networking. It provides TCP streams for
## reliable data transfer and UDP packets for low-latency communication.
##
## **Key C functions:**
## ```c
## int SDLNet_Init(void);
## TCPsocket SDLNet_TCP_Open(IPaddress *ip);
## int SDLNet_TCP_Send(TCPsocket sock, void *data, int len);
## UDPsocket SDLNet_UDP_Open(Uint16 port);
## ```
##
## ## Usage Example
##
## ```nim
## import sdl
##
## # TCP client example
## runMain:
##   let ctx = sdlInit()
##   defer: ctx.quit()
##
##   if initNet():
##     defer: quitNet()
##
##     # Connect to server
##     let ip = resolveHost("localhost", 8080)
##     if ip.isSome:
##       var server = openTcp(ip.get)
##       if server.isSome:
##         # Send data
##         discard server.get.send("Hello Server!")
##
##         # Receive response
##         var buffer: array[1024, char]
##         let received = server.get.recv(buffer)
##         if received > 0:
##           echo "Received: ", buffer[0 ..< received]
##
## # UDP server example
## runMain:
##   let ctx = sdlInit()
##   defer: ctx.quit()
##
##   if initNet():
##     defer: quitNet()
##
##     let socket = openUdp(9090)
##     if socket.isSome:
##       var udp = socket.get
##       let packet = newUdpPacket(1024)
##       if packet.isSome:
##         var pkt = packet.get
##         while true:
##           if udp.recv(pkt):
##             echo "Received UDP packet"
## ```
##
## ## Advantages over C SDL_net
##
## | C SDL_net                      | Nim SDL                     |
## |--------------------------------|-----------------------------|
## | `TCPsocket sock` manual close  | `TcpSocket` RAII auto-close |
## | `UDPpacket *pkt` manual free   | `UdpPacket` RAII auto-free  |
## | Manual memory management       | Automatic resource cleanup  |
## | Error-prone pointer arithmetic | Safe array operations       |
##
## ## Requirements
##
## Compile with `-d:net` flag. Requires SDL_net library installed.
##
## ## See Also
##
## - `sdl/core` - SDL initialization

when defined(net):
  import std/options
  import private/utils
  import version

  # =========================================================
  # 1. CONSTANTS AND SAFE TYPES (RAII)
  # =========================================================

  const
    inaddrAny* = 0x00000000'u32
      ## Wildcard address (bind to all interfaces).

    inaddrNone* = 0xFFFFFFFF'u32
      ## No address (invalid).

    inaddrLoopback* = 0x7F000001'u32
      ## Loopback address (127.0.0.1).

    inaddrBroadcast* = 0xFFFFFFFF'u32
      ## Broadcast address (255.255.255.255).

    maxUdpChannels* = 32
      ## Maximum number of UDP channels per socket.

    maxUdpAddresses* = 4
      ## Maximum number of addresses per UDP channel.

  type
    RawTcpSocketPtr* = distinct pointer
      ## Opaque pointer to a C TCP socket handle.

    RawUdpSocketPtr* = distinct pointer
      ## Opaque pointer to a C UDP socket handle.

    RawSocketSetPtr* = distinct pointer
      ## Opaque pointer to a C socket set handle.

    UdpChannel* = range[-1 .. maxUdpChannels - 1]
      ## UDP channel identifier. -1 means any channel.

  proc `==`*(a, b: RawTcpSocketPtr): bool {.borrow.}
    ## Compares two RawTcpSocketPtr values for equality.

  proc isNil*(p: RawTcpSocketPtr): bool {.borrow.}
    ## Checks if the raw TCP socket pointer is nil.

  proc `==`*(a, b: RawUdpSocketPtr): bool {.borrow.}
    ## Compares two RawUdpSocketPtr values for equality.

  proc isNil*(p: RawUdpSocketPtr): bool {.borrow.}
    ## Checks if the raw UDP socket pointer is nil.

  proc `==`*(a, b: RawSocketSetPtr): bool {.borrow.}
    ## Compares two RawSocketSetPtr values for equality.

  proc isNil*(p: RawSocketSetPtr): bool {.borrow.}
    ## Checks if the raw socket set pointer is nil.

  const anyChannel* = UdpChannel(-1)
    ## Refers to any available UDP channel for sending/receiving.

  {.push header: "SDL_net.h", bycopy, cdecl.}

  type
    IpAddress* {.importc: "IPaddress".} = object
      ## Network address with host and port for socket connections.
      host*: uint32  ## IP address in network byte order
      port*: uint16  ## Port number in network byte order

    RawUdpPacket {.importc: "UDPpacket".} = object
      channel*: cint
      data*: ptr UncheckedArray[uint8]
      len*: cint
      maxlen*: cint
      status*: cint
      address*: IpAddress

  {.pop.}

  type
    RawUdpPacketPtr = ptr RawUdpPacket
    RawUdpPacketVecPtr = ptr UncheckedArray[RawUdpPacketPtr]

  # =========================================================
  # 2. PRIVATE EXHAUSTIVE BINDINGS (FFI)
  # =========================================================

  {.push header: "SDL_net.h", importc, cdecl.}

  proc SDLNet_Linked_Version(): ptr Version
  proc SDLNet_Init(): cint
  proc SDLNet_Quit()

  proc SDLNet_ResolveHost(address: ptr IpAddress, host: cstring, port: uint16): cint
  proc SDLNet_ResolveIP(ip: ptr IpAddress): cstring
  proc SDLNet_GetLocalAddresses(addresses: ptr IpAddress, maxcount: cint): cint

  proc SDLNet_TCP_Open(ip: ptr IpAddress): RawTcpSocketPtr
  proc SDLNet_TCP_Accept(server: RawTcpSocketPtr): RawTcpSocketPtr
  proc SDLNet_TCP_GetPeerAddress(sock: RawTcpSocketPtr): ptr IpAddress
  proc SDLNet_TCP_Send(sock: RawTcpSocketPtr, data: pointer, len: cint): cint
  proc SDLNet_TCP_Recv(sock: RawTcpSocketPtr, data: pointer, maxlen: cint): cint

  proc SDLNet_AllocPacket(size: cint): RawUdpPacketPtr
  proc SDLNet_ResizePacket(packet: RawUdpPacketPtr, newsize: cint): cint
  proc SDLNet_AllocPacketV(howmany: cint, size: cint): RawUdpPacketVecPtr

  proc SDLNet_UDP_Open(port: uint16): RawUdpSocketPtr
  proc SDLNet_UDP_SetPacketLoss(sock: RawUdpSocketPtr, percent: cint)
  proc SDLNet_UDP_Bind(sock: RawUdpSocketPtr, channel: cint, address: ptr IpAddress): cint
  proc SDLNet_UDP_Unbind(sock: RawUdpSocketPtr, channel: cint)
  proc SDLNet_UDP_GetPeerAddress(sock: RawUdpSocketPtr, channel: cint): ptr IpAddress
  proc SDLNet_UDP_SendV(sock: RawUdpSocketPtr, packets: RawUdpPacketVecPtr, npackets: cint): cint
  proc SDLNet_UDP_Send(sock: RawUdpSocketPtr, channel: cint, packet: RawUdpPacketPtr): cint
  proc SDLNet_UDP_RecvV(sock: RawUdpSocketPtr, packets: RawUdpPacketVecPtr): cint
  proc SDLNet_UDP_Recv(sock: RawUdpSocketPtr, packet: RawUdpPacketPtr): cint

  proc SDLNet_AllocSocketSet(maxsockets: cint): RawSocketSetPtr
  proc SDLNet_AddSocket(s: RawSocketSetPtr, sock: pointer): cint
  proc SDLNet_DelSocket(s: RawSocketSetPtr, sock: pointer): cint
  proc SDLNet_CheckSockets(set: RawSocketSetPtr, timeout: uint32): cint
  proc SDLNet_SocketReady*(sock: pointer): cint

  proc SDLNet_Write16(value: uint16, area: pointer)
  proc SDLNet_Write32(value: uint32, area: pointer)
  proc SDLNet_Read16(area: pointer): uint16
  proc SDLNet_Read32(area: pointer): uint32

  proc SDLNet_TCP_Close(sock: RawTcpSocketPtr)
  proc SDLNet_UDP_Close(sock: RawUdpSocketPtr)
  proc SDLNet_FreePacket(packet: RawUdpPacketPtr)
  proc SDLNet_FreePacketV(packetV: RawUdpPacketVecPtr)
  proc SDLNet_FreeSocketSet(set: RawSocketSetPtr)

  proc SDLNet_GetError(): cstring

  {.pop.}

  type
    IpList*[N: static int] = object
      ## Fixed-size array of IP addresses with iteration support.
      data*: array[N, IpAddress]
      len*: int

    TcpSocket* = object
      ## RAII wrapper for a TCP socket. Automatically closes on scope exit.
      raw: RawTcpSocketPtr

    UdpSocket* = object
      ## RAII wrapper for a UDP socket. Automatically closes on scope exit.
      raw: RawUdpSocketPtr

    UdpPacket* = object
      ## RAII wrapper for a UDP packet. Automatically frees on scope exit.
      raw: RawUdpPacketPtr

    UdpPacketArray* = object
      ## RAII wrapper for an array of UDP packets. Automatically frees on scope exit.
      raw: RawUdpPacketVecPtr
      len*: int

    SocketSet* = object
      ## RAII wrapper for a socket set. Automatically frees on scope exit.
      raw: RawSocketSetPtr

  template freeResource(ptrField, freeProc: untyped) =
    if not ptrField.isNil:
      freeProc(ptrField)
      reset(ptrField)

  proc `=destroy`*(s: var TcpSocket)      = freeResource(s.raw, SDLNet_TCP_Close)
    ## Closes the TCP socket automatically when TcpSocket goes out of scope.

  proc `=destroy`*(s: var UdpSocket)      = freeResource(s.raw, SDLNet_UDP_Close)
    ## Closes the UDP socket automatically when UdpSocket goes out of scope.

  proc `=destroy`*(p: var UdpPacket)      = freeResource(p.raw, SDLNet_FreePacket)
    ## Frees the UDP packet automatically when UdpPacket goes out of scope.

  proc `=destroy`*(p: var UdpPacketArray) = freeResource(p.raw, SDLNet_FreePacketV)
    ## Frees the UDP packet array automatically when UdpPacketArray goes out of scope.

  proc `=destroy`*(s: var SocketSet)      = freeResource(s.raw, SDLNet_FreeSocketSet)
    ## Frees the socket set automatically when SocketSet goes out of scope.

  proc `=sink`*(dest: var TcpSocket; source: TcpSocket) = sinkImpl(dest, source)
    ## Move semantics: transfers TCP socket ownership without double-close.

  proc `=sink`*(dest: var UdpSocket; source: UdpSocket) = sinkImpl(dest, source)
    ## Move semantics: transfers UDP socket ownership without double-close.

  proc `=sink`*(dest: var UdpPacket; source: UdpPacket) = sinkImpl(dest, source)
    ## Move semantics: transfers UDP packet ownership without double-free.

  proc `=sink`*(dest: var SocketSet; source: SocketSet) = sinkImpl(dest, source)
    ## Move semantics: transfers socket set ownership without double-free.

  proc `=sink`*(dest: var UdpPacketArray; source: UdpPacketArray) = sinkImpl(dest, source)
    ## Move semantics: transfers packet array ownership without double-free.

  proc `=copy`*(dest: var TcpSocket, source: TcpSocket) {.error.}
    ## Copying is disabled to prevent double-close. Use move() instead.

  proc `=copy`*(dest: var UdpSocket, source: UdpSocket) {.error.}
    ## Copying is disabled to prevent double-close. Use move() instead.

  proc `=copy`*(dest: var UdpPacket, source: UdpPacket) {.error.}
    ## Copying is disabled to prevent double-free. Use move() instead.

  proc `=copy`*(dest: var SocketSet, source: SocketSet) {.error.}
    ## Copying is disabled to prevent double-free. Use move() instead.

  proc `=copy`*(dest: var UdpPacketArray, source: UdpPacketArray) {.error.}
    ## Copying is disabled to prevent double-free. Use move() instead.

  proc unsafeRaw*(s: TcpSocket): RawTcpSocketPtr {.inline.} = s.raw
    ## Extracts the raw TCP socket pointer. Only valid while `s` is in scope.

  proc unsafeRaw*(s: UdpSocket): RawUdpSocketPtr {.inline.} = s.raw
    ## Extracts the raw UDP socket pointer. Only valid while `s` is in scope.

  proc unsafeRaw*(s: UdpPacket): RawUdpPacketPtr {.inline.} = s.raw
    ## Extracts the raw UDP packet pointer. Only valid while `s` is in scope.

  proc unsafeRaw*(s: SocketSet): RawSocketSetPtr {.inline.} = s.raw
    ## Extracts the raw socket set pointer. Only valid while `s` is in scope.

  proc unsafeRaw*(s: var UdpPacketArray): RawUdpPacketVecPtr {.inline.} = s.raw
    ## Extracts the raw packet array pointer. Only valid while `s` is in scope.

  proc assumeRaw*(p: RawTcpSocketPtr): TcpSocket {.inline.} = TcpSocket(raw: p)
    ## Wraps a raw TCP socket pointer into a TcpSocket. Assumes ownership.

  proc assumeRaw*(p: RawUdpSocketPtr): UdpSocket {.inline.} = UdpSocket(raw: p)
    ## Wraps a raw UDP socket pointer into a UdpSocket. Assumes ownership.

  proc assumeRaw*(p: RawUdpPacketPtr): UdpPacket {.inline.} = UdpPacket(raw: p)
    ## Wraps a raw UDP packet pointer into a UdpPacket. Assumes ownership.

  proc assumeRaw*(p: RawSocketSetPtr): SocketSet {.inline.} = SocketSet(raw: p)
    ## Wraps a raw socket set pointer into a SocketSet. Assumes ownership.

  proc assumeRaw*(p: RawUdpPacketVecPtr, count: int): UdpPacketArray {.inline.} =
    ## Wraps a raw packet array pointer into a UdpPacketArray with length.
    UdpPacketArray(raw: p, len: count)


  # =========================================================
  # 3. PUBLIC API
  # =========================================================

  proc initNet*(): bool {.inline.} =
    ## Initializes the SDL_net library. Must be called before any networking operations.
    ## Returns `true` on success.
    ##
    ## **Example:**
    ## ```nim
    ## if initNet():
    ##   defer: quitNet()
    ##   # Network operations...
    ## ```
    sdlOk SDLNet_Init()

  proc quitNet*() {.inline.} =
    ## Shuts down the SDL_net library and releases resources.
    SDLNet_Quit()

  proc netLinkedVersion*(): Option[Version] {.inline.} =
    ## Returns the runtime version of the linked SDL_net library.
    ## Returns `none` if the version cannot be determined.
    let p = SDLNet_Linked_Version()
    if p.isNil: none(Version) else: some(p[])

  proc netError*(): cstring {.inline.} =
    ## Returns the last SDL_net error message.
    SDLNet_GetError()

  proc resolveHost*(host: string, port: int): Option[IpAddress] {.inline.} =
    ## Resolves a hostname to an IP address for the given port.
    ## Returns `some(IpAddress)` on success, `none` on failure.
    ##
    ## **Example:**
    ## ```nim
    ## let ip = resolveHost("localhost", 8080)
    ## if ip.isSome:
    ##   var server = openTcp(ip.get)
    ## ```
    var ip: IpAddress
    if sdlNoErr SDLNet_ResolveHost(addr ip, host.cstring, uint16(port)):
      none(IpAddress)
    else:
      some(ip)

  proc resolveIp*(ip: var IpAddress): cstring {.inline.} =
    ## Resolves an IP address back to a dotted-quad string (e.g., "192.168.1.1").
    SDLNet_ResolveIP(addr ip)

  proc localAddresses*(buffer: var openArray[IpAddress]): int {.inline.} =
    ## Fills the buffer with local network addresses.
    ## Returns the number of addresses found.
    if buffer.len == 0: return 0
    let count = SDLNet_GetLocalAddresses(addr buffer[0], cint(buffer.len))
    return max(0, int(count))

  proc localAddresses*[N: static int](): IpList[N] {.inline.} =
    ## Returns a fixed-size list of local network addresses.
    var result: IpList[N]
    result.len = localAddresses(result.data)
    return result

  proc `[]`*[N: static int](list: IpList[N], index: int): IpAddress {.inline.} =
    ## Accesses an IP address by index in the list. Bounds-checked.
    assert index >= 0 and index < list.len
    list.data[index]

  iterator items*[N: static int](list: IpList[N]): IpAddress =
    ## Iterates over all IP addresses in the list.
    for i in 0 ..< list.len:
      yield list.data[i]

  proc openTcp*(ip: var IpAddress): Option[TcpSocket] {.inline.} =
    ## Opens a TCP connection to the specified address.
    ##
    ## **Example:**
    ## ```nim
    ## let ip = resolveHost("localhost", 8080)
    ## if ip.isSome:
    ##   var server = openTcp(ip.get)
    ##   if server.isSome:
    ##     # Connection established
    ## ```
    SDLNet_TCP_Open(addr ip).toOption(TcpSocket)

  proc accept*(server: var TcpSocket): Option[TcpSocket] {.inline.} =
    ## Accepts an incoming TCP connection from a listening socket.
    ## Returns `some(TcpSocket)` on success, `none` if no connection pending.
    SDLNet_TCP_Accept(server.raw).toOption(TcpSocket)

  proc peerAddress*(sock: var TcpSocket): Option[IpAddress] {.inline.} =
    ## Returns the remote address of the connected TCP socket.
    let raw = SDLNet_TCP_GetPeerAddress(sock.raw)
    if raw.isNil: none(IpAddress)
    else: some(raw[])

  proc send*(sock: var TcpSocket, data: string): int {.inline, discardable.} =
    ## Sends data over a TCP connection.
    ##
    ## **Example:**
    ## ```nim
    ## discard server.send("Hello!")
    ## discard server.send(binaryData)
    ## ```
    if data.len == 0: return 0
    SDLNet_TCP_Send(sock.raw, unsafeAddr data[0], cint(data.len))

  proc recv*(sock: var TcpSocket, buffer: var openArray[char]): int {.inline.} =
    ## Receives data from a TCP connection into a buffer.
    ##
    ## **Example:**
    ## ```nim
    ## var buffer: array[1024, char]
    ## let received = server.recv(buffer)
    ## if received > 0:
    ##   echo "Received: ", buffer[0 ..< received]
    ## ```
    if buffer.len == 0: return 0
    let bytesRead = SDLNet_TCP_Recv(sock.raw, addr buffer[0], cint(buffer.len))
    return bytesRead

  proc recv*(sock: var TcpSocket, buffer: var string, maxLen: int = 1024): int {.inline.} =
    ## Receives data from a TCP connection into a resized string buffer.
    ## Returns the number of bytes received, or -1 on error.
    buffer.setLen(maxLen)
    let bytesRead = SDLNet_TCP_Recv(sock.raw, addr buffer[0], cint(maxLen))
    if bytesRead <= 0:
      buffer.setLen(0)
      return int(bytesRead)
    buffer.setLen(bytesRead)
    return int(bytesRead)

  proc newUdpPacket*(size: int): Option[UdpPacket] {.inline.} =
    ## Allocates a new UDP packet with the given maximum payload size.
    ## Returns `some(UdpPacket)` on success, `none` on failure.
    SDLNet_AllocPacket(cint(size)).toOption(UdpPacket)

  proc resize*(packet: var UdpPacket, newSize: int): bool {.inline, discardable.} =
    ## Resizes the UDP packet's payload buffer to the given size.
    ## Returns `true` on success.
    SDLNet_ResizePacket(packet.raw, cint(newSize)) == newSize

  proc `address=`*(p: var UdpPacket, ip: IpAddress) {.inline.} =
    ## Sets the source/destination address for the UDP packet.
    p.raw.address = ip

  proc address*(p: var UdpPacket): IpAddress {.inline.} =
    ## Returns the source/destination address of the UDP packet.
    p.raw.address

  proc `channel=`*(p: var UdpPacket, channel: UdpChannel) {.inline.} =
    ## Sets the UDP channel for this packet.
    p.raw.channel = cint(channel)

  proc channel*(p: var UdpPacket): UdpChannel {.inline.} =
    ## Returns the UDP channel of this packet.
    UdpChannel(p.raw.channel)

  proc write*(p: var UdpPacket, data: openArray[char]) {.inline.} =
    ## Writes character data into the UDP packet's payload buffer.
    ## Truncates if data exceeds the buffer capacity.
    let copyLen = min(data.len, int(p.raw.maxlen))
    if copyLen > 0:
      copyMem(p.raw.data, unsafeAddr data[0], copyLen)
    p.raw.len = cint(copyLen)

  proc write*(p: var UdpPacket, data: string) {.inline.} =
    ## Writes a string into the UDP packet's payload buffer.
    if data.len == 0: return
    p.write(toOpenArray(data, 0, data.len - 1))

  proc read*(p: var UdpPacket, buffer: var openArray[char]): int {.inline.} =
    ## Reads the UDP packet's payload into a character buffer.
    ## Returns the number of bytes read.
    let copyLen = min(int(p.raw.len), buffer.len)
    if copyLen > 0:
      copyMem(addr buffer[0], p.raw.data, copyLen)
    return copyLen

  proc read*(p: var UdpPacket, buffer: var string): int {.inline.} =
    ## Reads the UDP packet's payload into a string.
    ## Returns the number of bytes read.
    let packetLen = int(p.raw.len)
    if packetLen <= 0:
      buffer.setLen(0)
      return 0
    buffer.setLen(packetLen)
    copyMem(addr buffer[0], p.raw.data, packetLen)
    return packetLen

  proc newUdpPacketArray*(howMany, size: int): Option[UdpPacketArray] {.inline.} =
    ## Allocates an array of UDP packets with the given count and payload size.
    ## Returns `some(UdpPacketArray)` on success, `none` on failure.
    let raw = SDLNet_AllocPacketV(cint(howMany), cint(size))
    if raw.isNil: none(UdpPacketArray)
    else: some(UdpPacketArray(raw: raw, len: howMany))

  iterator items*(vec: UdpPacketArray): UdpPacket =
    ## Iterates over all packets in the UDP packet array.
    for i in 0 ..< vec.len:
      yield UdpPacket(raw: vec.raw[i])

  proc openUdp*(port: int = 0): Option[UdpSocket] {.inline.} =
    ## Opens a UDP socket on the given port. Port 0 selects any available port.
    ## Returns `some(UdpSocket)` on success, `none` on failure.
    ##
    ## **Example:**
    ## ```nim
    ## let socket = openUdp(9090)
    ## if socket.isSome:
    ##   # Ready to send/receive
    ## ```
    SDLNet_UDP_Open(uint16(port)).toOption(UdpSocket)

  proc setPacketLoss*(sock: var UdpSocket, percent: int) {.inline.} =
    ## Simulates packet loss for testing (0 = no loss, 100 = all lost).
    SDLNet_UDP_SetPacketLoss(sock.raw, cint(percent))

  proc bindChannel*(sock: var UdpSocket, address: var IpAddress, channel: UdpChannel): UdpChannel {.inline.} =
    ## Binds a UDP socket channel to a specific address.
    let res = SDLNet_UDP_Bind(sock.raw, cint(channel), addr address)
    assert res != -1, "Limit of " & $maxUdpAddresses & " addresses per channel reached!"
    return UdpChannel(res)

  proc unbindChannel*(sock: var UdpSocket, channel: UdpChannel) {.inline.} =
    ## Unbinds a UDP channel from its address.
    SDLNet_UDP_Unbind(sock.raw, cint(channel))

  proc peerAddress*(sock: var UdpSocket, channel: UdpChannel): Option[IpAddress] {.inline.} =
    ## Returns the address bound to the given UDP channel.
    let raw = SDLNet_UDP_GetPeerAddress(sock.raw, cint(channel))
    if raw.isNil: none(IpAddress)
    else: some(raw[])

  proc send*(sock: var UdpSocket, packet: var UdpPacket, channel: UdpChannel = anyChannel): bool {.inline.} =
    ## Sends a UDP packet on the specified channel. Returns `true` on success.
    SDLNet_UDP_Send(sock.raw, cint(channel), packet.raw) != 0

  proc send*(sock: var UdpSocket, packets: var UdpPacketArray): int {.inline.} =
    ## Sends an array of UDP packets. Returns the number sent.
    SDLNet_UDP_SendV(sock.raw, packets.raw, cint(packets.len))

  proc recv*(sock: var UdpSocket, packet: var UdpPacket): bool {.inline.} =
    ## Receives a UDP packet. Returns `true` if a packet was received.
    SDLNet_UDP_Recv(sock.raw, packet.raw) > 0

  proc recv*(sock: var UdpSocket, packets: var UdpPacketArray): int {.inline.} =
    ## Receives multiple UDP packets. Returns the number received.
    SDLNet_UDP_RecvV(sock.raw, packets.raw)

  proc newSocketSet*(maxSockets: int): Option[SocketSet] {.inline.} =
    ## Creates a socket set for monitoring multiple sockets for activity.
    SDLNet_AllocSocketSet(cint(maxSockets)).toOption(SocketSet)

  proc add*(s: var SocketSet, sock: var TcpSocket): int {.inline, discardable.} =
    ## Adds a TCP socket to the set for activity monitoring.
    SDLNet_AddSocket(s.raw, cast[pointer](sock.raw))

  proc add*(s: var SocketSet, sock: var UdpSocket): int {.inline, discardable.} =
    ## Adds a UDP socket to the set for activity monitoring.
    SDLNet_AddSocket(s.raw, cast[pointer](sock.raw))

  proc del*(s: var SocketSet, sock: var TcpSocket): int {.inline, discardable.} =
    ## Removes a TCP socket from the set.
    SDLNet_DelSocket(s.raw, cast[pointer](sock.raw))

  proc del*(s: var SocketSet, sock: var UdpSocket): int {.inline, discardable.} =
    ## Removes a UDP socket from the set.
    SDLNet_DelSocket(s.raw, cast[pointer](sock.raw))

  proc check*(s: var SocketSet, timeoutMs: int = 0): int {.inline.} =
    ## Checks all sockets in the set for activity with an optional timeout in ms.
    ## Returns the number of sockets with activity.
    SDLNet_CheckSockets(s.raw, uint32(timeoutMs))

  proc hasActivity*(s: SocketSet, sock: var TcpSocket): bool {.inline.} =
    ## Checks if a TCP socket in the set has pending data after `check()`.
    sdlNonZero SDLNet_SocketReady(cast[pointer](sock.raw))

  proc hasActivity*(s: SocketSet, sock: var UdpSocket): bool {.inline.} =
    ## Checks if a UDP socket in the set has pending data after `check()`.
    sdlNonZero SDLNet_SocketReady(cast[pointer](sock.raw))

  proc isReady*(sock: var TcpSocket): bool {.inline.} =
    ## Checks if a TCP socket has data pending (requires being in a checked set).
    sdlNonZero SDLNet_SocketReady(cast[pointer](sock.raw))

  proc isReady*(sock: var UdpSocket): bool {.inline.} =
    ## Checks if a UDP socket has data pending (requires being in a checked set).
    sdlNonZero SDLNet_SocketReady(cast[pointer](sock.raw))

  proc write16*(value: uint16, area: pointer) {.inline.} =
    ## Writes a 16-bit value in network byte order to memory.
    SDLNet_Write16(value, area)

  proc write32*(value: uint32, area: pointer) {.inline.} =
    ## Writes a 32-bit value in network byte order to memory.
    SDLNet_Write32(value, area)

  proc read16*(area: pointer): uint16 {.inline.} =
    ## Reads a 16-bit value in network byte order from memory.
    SDLNet_Read16(area)

  proc read32*(area: pointer): uint32 {.inline.} =
    ## Reads a 32-bit value in network byte order from memory.
    SDLNet_Read32(area)
