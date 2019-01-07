unit ClusterChat;

interface

uses
  windows, Messages, SysUtils, Classes, Controls, wsocket, ExtCtrls, VortexCommon;

type
  TStartevent     = procedure (Sender : TObject) of object;
  TUserConnect    = procedure (Sender : TObject; ThreadID, Nickname, hostname : string) of Object;
  TUserDisconnect = procedure (Sender : TObject; ThreadID, Nickname, hostname : string) of Object;
  TChatTimeOut    = procedure (Sender : TObject; Nickname, IPAddress : string) of Object;
  TUserMessage    = procedure (Sender : TObject; ThreadID, Nickname, hostname, ReceivedMessage : string) of Object;
  TChatException  = procedure (sender : TObject) of Object;

type
 TDccSort         = ( dsNone,                     dsConnected,
                      dsListening,                dsConnecting
                    );
type
 TEventType       = ( etNone,                     etDeleteThread,
                      etMessage,                  etDisconnect,
                      etConnected,                etTimeOut
                    );

type
  TClusterChat = class(TComponent)
  private
    FChatList : TStringlist;
    FUserMessage : TUserMessage;
    FChatException : TChatException;
    FUserConnect : TUserConnect;
    FChatTimeout : TChatTimeOut;
    FThreadCountID : integer;
    FComponentReady : Tstartevent;
    FUserDisconnect : TUserDisconnect;
    FTimerTimeOut: integer;
    function SetupListenSocket(SocketPort : integer) : TVortexSocket;
    function SetupChatConnection(ServerSocket: TVortexSocket;Method : TDccSort = dsnone): TVortexSocket;
    function SetupRemoteConnection(RemoteHost, RemotePort: string): TVortexSocket;
    function GetChatCount: Integer;
  protected
    procedure OnListenConnect (Sender: TObject; Error: Word);
    procedure Loaded; override;
  public
    procedure SendMessageID(ThreadID, ChatMessage: string);
    procedure SendMessageNick(Nickname, ChatMessage: string);
    procedure KillThreadID(ThreadID : string);
    procedure ThreadConnect(NickName, Remotehost, Remoteport : string);
    Function ThreadInitChat(Nickname : string = '';port : integer = 0) : string;
    destructor destroy; override;
    constructor Create  (AOwner : TComponent); override;
  published
    property ChatTimeout    : integer read FTimerTimeOut write FTimerTimeOut;
    property ChatCount      : Integer read GetChatCount;
    property OnComponentReady : TStartEvent  read FComponentReady write FComponentReady;
    property OnMessage        : TUserMessage read FUserMessage write FUserMessage;
    property OnUserConnect    : TUserConnect read FUserConnect write FUserConnect;
    property OnChatException  : TChatException read FChatException write FChatException;
    property OnChatTimeout    : TChatTimeOut read FChatTimeOut write FChatTimeOut;
    property OnUserDisconnect : TUserDisconnect read FUserDisconnect write FUserDisconnect;
  end;

Type
  TChatConnection = class(TThread)
  private
    FSort      : TDccSort;
    FEventType : TEventType;
    FNick      : string;
    FLastMsg   : string;
    FIPAddress : string;
    FSessionID : string;
    FTimeOut   : TTimer;
    FSocket    : TVortexSocket;
    FListenSock : TVortexSocket;
    FMainThread : TClusterChat;
    procedure OnThreadDisconnect (Sender: TObject; Error: Word);
    procedure OnThreadSocketConnect (Sender: TObject; Error: Word);
    procedure OnThreadSocketDataAvailable (Sender: TObject; Error: Word);
    procedure OnThreadSocketConnecting(Sender: TObject; Error: Word);
    procedure OnThreadTimer(Sender: TObject);
  public
    procedure SendChatMessage(socket : TVortexSocket; ChatMessage: string);
    procedure DoMessages;
    procedure execute; override;
    destructor Destroy; override;
  Published
    property ChatNick       : string read Fnick write Fnick;
    property ChatIPAddr     : string read FIPAddress write FIPAddress;
    property ChatClientSort : TDccSort read FSort write FSort;
    property ChatMainThread : TClusterChat read FMainThread write FMainThread;
    property ChatSocket     : TVortexSocket read Fsocket write FSocket;
  end;

const
  CrLf = #13#10;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('joepezT', [TClusterChat]);
end;

procedure TClusterChat.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in ComponentState) then
  begin
    if Assigned(FComponentReady) then
       FComponentReady(self);
  end;
end;

destructor TClusterChat.destroy;
begin
  FreeAndNil(FChatList);
  inherited;
end;

function TClusterChat.SetupChatConnection(ServerSocket: TVortexSocket;Method : TDccSort): TVortexSocket;
Var
Socket     : TVortexSocket;

begin
  socket := TVortexSocket.create(nil);
  with socket do
  try
//    OnSessionClosed  := OnDisconnect;
    HSocket := ServerSocket.Accept;
  except
    result := nil;
    exit;
  end;
  result := socket;
end;

function TClusterChat.SetupListenSocket(SocketPort : integer) : TVortexSocket;
Var
Socket : TVortexSocket;

begin
  socket := TVortexSocket.create(nil);
  with socket do
  try
    OnSessionAvailable := OnListenConnect;
//    OnSessionClosed    := OnDisconnect;
    Addr  := '0.0.0.0';
    proto := 'tcp';
    port  := IntToStr(SocketPort);
    listen;
  except
    result := nil;
    exit;
  end;
  result := socket;
end;

Function TClusterChat.SetupRemoteConnection(RemoteHost, RemotePort : string) : TVortexSocket;
Var
Socket     : TVortexSocket;

begin
  socket := TVortexSocket.create(nil);
  with socket do
  try
//    OnSessionClosed := OnDisconnect;
    proto := 'tcp';
    Addr  := RemoteHost;
    port  := RemotePort;
  except
    Result := nil;
    exit;
  end;
  result := socket;
end;

Function TClusterChat.ThreadInitChat(Nickname : string = '';port : integer = 0) : string;
var
Chat   : TChatConnection;

begin
  chat := TChatConnection.Create(true);
  with Chat do
  begin
    FMainThread := self;
    FSort       := dsListening;
    FNick       := Nickname;
    FIPAddress  := '0.0.0.0';
    FListenSock := SetupListenSocket(port);
    FChatList.AddObject(format('%s',[FSessionID]),Self);
    if (FListenSock <> nil) then
    with FListenSock do
    begin
      if (FTimerTimeOut <> 0) then
      begin
        FTimeOut    := TTimer.create(nil);
        with FTimeOut do
        begin
          OnTimer  := OnThreadTimer;
          Interval := (FTimerTimeOut*1000);
          enabled  := true;
        end;
      end;
      OnSessionAvailable := OnThreadSocketConnecting;
      OnDataAvailable    := OnThreadSocketDataAvailable;
      result := GetXPort;
      chat.resume;
    end else
    FreeAndNil(chat);
  end;
end;

procedure TClusterChat.OnListenConnect(Sender: TObject;  Error: Word);
var
Chat     : TChatConnection;
begin
  chat     := TChatConnection.create(true);
  with chat do
  begin
    FMainThread := Self;
    FSocket := SetupChatConnection(TVortexSocket(sender));
    if (FSocket <> nil) then
    begin
      with FSocket do
      OnDataAvailable := OnThreadSocketDataAvailable;

      if assigned(FuserConnect) then
         FuserConnect(TVortexSocket(sender),FSessionID,FNick,FIPAddress);
      FSort := dsConnecting;
      chat.Resume;
    end else
    FreeAndNil(chat);
  end;
end;

procedure TClusterChat.SendMessageID(ThreadID, ChatMessage : string);
var
i : integer;
begin
  if (FChatList <> nil) then
  begin
    i := FChatList.IndexOf(ThreadID);
    if (i <> -1) then
    with TChatConnection(FChatList.Objects[i]) do
         SendChatMessage(FSocket,ChatMessage);
  end;
end;

procedure TClusterChat.SendMessageNick(Nickname, ChatMessage: string);
var
i : integer;
begin
  if (FChatList <> nil) then
  begin
    for i := 0 to FChatList.Count -1 do
    with TChatConnection(FChatList.Objects[i]) do
    if lowercase(nickname) = lowercase(FNick) then
    begin
      with TChatConnection(FChatList.Objects[i]) do
           SendChatMessage(FSocket,ChatMessage);
      exit;
    end;
  end;
end;

procedure TClusterChat.ThreadConnect(NickName, Remotehost, Remoteport : string);
var
Chat : TChatConnection;

begin
  inc(FThreadCountID);
  chat := TChatConnection.Create(true);
  with chat do
  begin
    FSocket := SetupRemoteConnection(Remotehost,Remoteport);
    if (FSocket <> nil) then
    begin
      { if timeout = 0 then we let it be unlimited (never timeout) }
      if (FTimerTimeOut <> 0) then
      begin
        FTimeOut := TTimer.create(nil);
        with FTimeOut do
        begin
          OnTimer := OnThreadTimer;
          Interval := (FTimerTimeOut*1000);
          enabled := true;
        end;
      end;

      FSort       := dsConnecting;
      FSessionID  := IntToStr(FThreadCountID);
      FMainThread := Self;
      FNick       := NickName;
      FChatList.AddObject(FSessionID,chat);
      with FSocket do
      begin
        OnDataAvailable := OnThreadSocketDataAvailable;
        OnSessionConnected := OnThreadSocketConnect;
        OnSessionClosed := OnThreadDisconnect;
      end;
      chat.Resume;
    end else
    FreeAndNil(chat);
  end;
end;

constructor TClusterChat.Create(AOwner: TComponent);
begin
  inherited Create(Aowner);
  FChatList := TStringList.Create;
end;






{ TChatConnection }{ TChatConnection }{ TChatConnection }{ TChatConnection }{ TChatConnection }
{ TChatConnection }{ TChatConnection }{ TChatConnection }
{ TChatConnection }{ TChatConnection }
{ TChatConnection }

procedure TChatConnection.execute;
begin
  if (FSort = dsConnecting) then
  FSocket.Connect;

  { just loop till we are dead :P } 
  while (not Terminated) or
        (FSocket.State <> wsClosed) do
  sleep(1);

  { we are finished }
  if FTimeOut <> nil then
  FreeAndNil(FTimeOut);

  FEventType := etDeleteThread;
  Synchronize(DoMessages);
end;

procedure TChatConnection.OnThreadSocketConnecting(Sender: TObject;
  Error: Word);
begin
  if FTimeOut <> nil then
  FreeAndNil(FTimeOut);

  FListenSock := TVortexSocket(sender);
  FEventType  := etConnected;
  Synchronize(DoMessages);

  with FSocket do
  begin
    FIPAddress      := GetPeerAddr;
    OnDataAvailable := OnThreadSocketDataAvailable;
    OnSessionClosed := OnThreadDisconnect;
  end;
end;

procedure TChatConnection.OnThreadSocketConnect(Sender: TObject;
  Error: Word);
begin
  FListenSock := TVortexSocket(sender);
  FEventType  := etConnected;
  Synchronize(DoMessages);

  with FSocket do
  begin
    FIPAddress      := GetPeerAddr;
    OnDataAvailable := OnThreadSocketDataAvailable;
    OnSessionClosed := OnThreadDisconnect;
  end;

  { Free up the listening socket }
  if (FSort = dsListening) then
  begin
    FListenSock.Close;
    FreeAndNil(FlistenSock);
  end;
end;

procedure TChatConnection.SendChatMessage(socket : TVortexSocket; ChatMessage: string);
begin
  if (socket <> nil) then
  Socket.SendStr(ChatMessage + CrLf)
end;

function TClusterChat.GetChatCount: Integer;
begin
 result := FChatList.Count;
end;

procedure TChatConnection.OnThreadTimer(Sender: TObject);
begin
  FEventType := etTimeOut;
  Synchronize(DoMessages);

  FreeAndNil(Self);
end;

procedure TChatConnection.OnThreadDisconnect(Sender: TObject; Error: Word);
begin
  { terminate thread }
  TVortexSocket(sender).Abort;
  FEventType := etDisconnect;
  Synchronize(DoMessages);
end;

procedure TChatConnection.OnThreadSocketDataAvailable(Sender: TObject;
  Error: Word);
begin
  FLastMsg := trim(TVortexSocket(sender).ReceiveStr);
  if (trim(FLastMsg) <> '') then
  begin { avoid a blank message }
    FEventType := etMessage;
    Synchronize(DoMessages);
  end;
end;

procedure TChatConnection.DoMessages;
var
i : integer;

begin
  with TClusterChat(FMainThread) do
  try
    try
      case (FEventType) of

        { triggers when we are receiving a message }
        etMessage:
        begin
          If assigned(FUserMessage) then
             FUserMessage(self, FSessionID, FNick, FIPAddress, FLastMsg);
        end;

        { triggers when we are connected }
        etConnected:
        begin
          inc(FThreadCountID);

          FSessionID := IntToStr(FThreadCountID);
          if FSort = dsListening then
          FSocket := SetupChatConnection(FListenSock);
          FIPAddress := FSocket.GetPeerAddr;
          
          FChatList.AddObject(FSessionID,Self);
          if assigned(FuserConnect) then
             FuserConnect(FSocket,FSessionID,FNick,FIPAddress);
        end;

        { triggers when disconnected }
        etDisconnect:
        begin
          if assigned(FuserDisconnect) then
             FUserDisconnect(FSocket,FSessionID,FNick,FIPAddress);
             terminate;
        end;

        etTimeOut:
        begin
          if assigned(FchatTimeOut) then
             FchatTimeOut(self,FNick,FIPAddress);
        end;

       { when the thread is finished, it's a good idea to remove it from the list }
       etDeleteThread:
        with FChatList do
        begin
          if (FSocket <> nil) then FreeAndNil(FSocket);
          if (FListenSock <> nil) then FreeAndNil(FListenSock);
          i := IndexOf(FSessionID);
          if (i <> -1) then Delete(i);
        end;
       { end of case statement }
      end;
    except
      { some error }
      if assigned(FChatException) then
      FChatException(self)
    end;

  finally
    if (self <> nil) then
    begin
      FEventType   := etNone;
      FLastMsg := '';
    end;
  end;
end;

destructor TChatConnection.Destroy;
begin
  if FTimeOut <> nil then
  FreeAndNil(FTimeOut);

  FEventType := etDeleteThread;
  Synchronize(DoMessages);
  inherited;
end;

procedure TClusterChat.KillThreadID(ThreadID: string);
var
i : integer;
begin
  if (FChatList <> nil) then
  begin
    i := FChatList.IndexOf(ThreadID);
    if (i <> -1) then
    with TChatConnection(FChatList.Objects[i]) do
    Terminate;
  end;
end;

end.

