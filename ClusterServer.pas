unit ClusterServer;
{
  Cluster DCC Server component by joepezT

  IRC: joepezT
  Email: Gothic(a)bluezone.no (Primary mail)  - (a) = @
         vortex(a)berzerk.net (questions regarding this component)

  Main purpose:
  Easy implementation of Direct Communication over IRC.
  This component is under development

  Chat Protocol
  Client connects to Server and sends:
  100 client nickname
  When Server receives this, it sends:
  101 server nickname
  Connection is established, users can now chat.

  Fserve Protocol
  Client connects to Server and sends:
  110 client nickname
  When Server receives this, it sends:
  111 server nickname
  Connection is established, user can now access fserve.

  Send Protocol
  Client connects to Server and sends:
  120 client nickname file size filename
  When Server receives this, it sends:
  121 server nickname resume position

  Where resume position is between 0 and file size, and is required.
  Connection is established, and Server dcc gets the file.

  Get Protocol
  Client connects to Server and sends:
  130 client nickname filename
  When Server receives this, it sends:
  131 server nickname file size
  When Client receives this, it sends:
  132 client nickname resume position
  Where resume position is between 0 and file size, and is required.
  Connection is established, and Server dcc sends the file.

  Other
  If server receives unexpected information, or doesn't receive info 15 seconds after initial connection, it closes the connection.

  If service is unavailable, server sends:
  150 unavailable

  If server rejects connection, it sends:
  151 rejected

  download ICS from www.overbyte.be
  You can use this component freely as long as you mention my name :-)
}

interface

uses
  SysUtils, Classes, Controls, wsocket,
  vortexcommon, clusterfile, clusterchat;

type
  TClusterEvents = class(Tobject)
  end;
   Tstartevent     = procedure of object;

Type
  TClusterClass = class(TVortexSocket)
  private
    FUserNick : string;
  public
  published
    property Usernick : string read FUserNick Write FUsernick;
  end;

type
  TClusterServer = class(TComponent)
  private
    FStartEvent     : Tstartevent;
    FDccFileSource  : TClusterFile;
    FDccChatSource  : TClusterChat;
    MainSocket      : TVortexSocket;
    FListenport     : Integer;
    FMyNick         : string;
    procedure SetDCCFileSource(const Value: TClusterFile);
    procedure SetDCCChatSource(const Value: TClusterChat);
  protected
    procedure OnConnectDataAvailable(Sender: TObject; Error: Word);
    procedure OnSocketDataAvailable(Sender: TObject; Error: Word);
    procedure OnSocketClosed(Sender: TObject; Error: Word);
    procedure OnSocketConnected(Sender: TObject; Error: Word);
  public
    procedure StartDccServer;
    procedure StopDccServer;
    procedure SetupServer(RemoteHost, RemotePort, FileName : string; FileSize: Int64 = -1);
    procedure Loaded; override;

    constructor Create  (AOwner : TComponent); override;
    destructor  Destroy; override;
  published
    property DccFileSource : TClusterFile read FDccFileSource Write SetDCCFileSource;
    property DccChatSource : TClusterChat read FDccChatSource Write SetDCCChatSource;
    property GetListenPort : Integer  read Flistenport;
    property ListenPort : Integer     read FListenPort write FListenPort default 59;
    property MyNick     : String      read FMyNick     write FMyNick;
    property OnStarted  : TStartEvent read FStartEvent write FStartEvent;
  end;

type
  TPZSocket = class (TVortexSocket)
  private
    FCustomSocket  : TVortexSocket;
    FSocketCommand : string;
    FSocketNick    : string;
    FFilename      : string;
    FFilePath      : string;
    FFileSize      : Int64;
    ComponentID    : Integer;
    ComponentOwner : TClusterFile;
  protected
    procedure OnThreadSendError(Sender: TObject);
    procedure OnSocketConnect(Sender: TObject; Error: Word);
    procedure OnSocketDataAvailable(Sender: TObject; Error: Word);
    procedure OnSocketDisconnected(Sender: TObject; Error: Word);
    destructor Destroy; override;
  public
  published
    property SetCommand : string write FSocketCommand;
  end;


procedure Register;

implementation


function GetFileSize(AFile: string): int64;
var
SearchRec: TSearchRec;
begin
  Result := 0;
  if ( FindFirst(AFile, faAnyFile, SearchRec) = 0 ) then
  begin
    if ( (SearchRec.Attr and faDirectory) <> faDirectory ) then
    begin
    { it is a normal file }
      Result := SearchRec.Size;
      FindClose(SearchRec);
    end
    else begin { it is a Directory }
      FindClose(SearchRec);
      if ( FindFirst(AFile + '\*.*', faAnyFile, SearchRec) = 0 ) then
      repeat
        if ( (SearchRec.Name <> '.') and (SearchRec.Name <> '..') )
        then
          Result := Result + GetFileSize(AFile + '\' +
          SearchRec.Name);
      until (FindNext(SearchRec) <> 0 );
    end;
  end;
end;

procedure Register;
begin
  RegisterComponents('joepezT', [TClusterServer]);
end;

function IsNumeric( Value:String ):Boolean;
var
  Code : Integer;
  Tmp  : Integer;
begin
  Val ( Value, tmp, Code );
  Result := Code = 0;
end;


{ TClusterComponent }

constructor TClusterServer.Create(AOwner: TComponent);
begin
  inherited Create(Aowner);
  if not (csDesigning in ComponentState) then
  FListenport := 59;
  
end;

destructor TClusterServer.Destroy;
begin
  FreeAndNil(MainSocket); 
  inherited;
end;

procedure TClusterServer.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in ComponentState) then
  if Assigned(FStartEvent) then
     FStartEvent;
end;

procedure TClusterServer.OnConnectDataAvailable(Sender: TObject;  Error: Word);
begin

end;

procedure TClusterServer.OnSocketClosed(Sender: TObject; Error: Word);
begin

end;

procedure TClusterServer.OnSocketConnected(Sender: TObject; Error: Word);
var
NewSocket : TVortexSocket;

begin
  NewSocket := TVortexSocket.Create(TVortexSocket(Sender));
  with NewSocket do
  begin
    OnSessionClosed := OnSocketClosed;
    OnDataAvailable := OnSocketDataAvailable;
    HSocket := TVortexSocket(Sender).Accept;
  end;
end;

procedure TClusterServer.OnSocketDataAvailable(Sender: TObject;
  Error: Word);
var
i        : Integer;
Num      : Integer;
temp     : string;
received : string;
FileName : string;
FileSize : string;
NickName : string;
ResumePosition : string;

begin
  with TVortexSocket(Sender) do
  begin
    Received := Trim(ReceiveStr);

    if IsNumeric(Copy(received,1,3)) then
    begin
      Num := StrToInt(Copy(received,1,Pos(#32,received)-1));
      Delete(received,1,Pos(#32,received));
    end;

    case Num of
    110: begin
           NickName := Copy(received,1,Pos(#32,received)-1);
           Delete(received,1,Pos(#32,received));
         end;

    120: begin  // client connects
           NickName := Copy(received,1,Pos(#32,received)-1);
           Delete(received,1,Pos(#32,received));

           FileSize := Copy(received,1,Pos(#32,received)-1);
           Delete(received,1,Pos(#32,received));

           FileName := Copy(received,1,Length(received));
           Delete(received,1,Pos(#32,received));

           with FDccFileSource do
           DUPGetFile(FileName,FileSize,NickName,0,HSocket);

           SendStr(format('121 server %s 0',[FMyNick]));
          end;
    121: with TVortexSocket(Sender) do // server responds
           begin
             received := Trim(ReceiveStr);
             Delete(received,1,4);
             NickName := trim(Copy(received,1,Pos(#32,received)-1));
             Delete(received,1,Pos(#32,received));
             ResumePosition := received;
             with FDccFileSource do
             DUPSendFile('',NickName,StrToInt(ResumePosition),HSocket);
           end;
    150,
    151: begin
          { service unavailable / Rejected}
          Release;
         end;
        { end of case }
    end;
    { end of socket }
  end;
end;

procedure TClusterServer.SetDCCChatSource(const Value: TClusterChat);
begin
  FDccChatSource := Value;
end;

procedure TClusterServer.SetDCCFileSource(const Value: TClusterFile);
begin
  FDccFileSource := Value;
end;

procedure TClusterServer.StartDccServer;
begin
  if Assigned(MainSocket) then
  MainSocket.Free;

  MainSocket := TVortexSocket.Create(self);
  with MainSocket do
  begin
    OnSessionAvailable := OnSocketConnected;
    OnSessionClosed    := OnSocketClosed;
    Addr  := '0.0.0.0';
    Port  := IntToStr(GetListenPort);
    Proto := 'tcp';
    LineEnd := #13#10;
    LineMode := True;
    Listen;
  end;

end;

procedure TClusterServer.StopDccServer;
begin
  if Assigned(MainSocket) then
  MainSocket.Free;
end;

{ TPZSocket }

destructor TPZSocket.Destroy;
begin
  inherited Destroy;
end;

procedure TPZSocket.OnSocketConnect(Sender: TObject; Error: Word);
begin
  TVortexSocket(Sender).SendStr(FSocketCommand + #13#10);
end;

procedure TClusterServer.SetupServer(RemoteHost, RemotePort, FileName : string; FileSize: Int64 = -1);
var
SocketThread : TPZSocket;

begin
  SocketThread := TPZSocket.Create(self);
  with SocketThread do
  begin
    if FileSize = -1 then
    FileSize := GetFileSize(FileName);

    setcommand := format('120 client %s %d %s',[mynick,filesize,FileName]);

    FCustomSocket := TVortexSocket.Create(Self);
    FFileSize := FileSize;
    FFilename := FileName;
    FSocketNick := FMyNick;
    with FCustomSocket do
    begin
      OnDataAvailable := OnSocketDataAvailable;
      OnError         := OnThreadSendError;
      OnSessionConnected := OnSocketConnect;
      OnSessionClosed := OnSocketDisconnected;
      Port := RemotePort;
      Addr := RemoteHost;
      Tag := Integer(Pointer(Self));
      Connect;
    end;

  end;

end;

procedure TPZSocket.OnSocketDataAvailable(Sender: TObject; Error: Word);
var
received : string;
NickName : string;
ResumePosition : string;

begin
  with TVortexSocket(Sender) do
  begin
    received := Trim(ReceiveStr);
    if Copy(received,1,3) = '121' then
    begin
      Delete(received,1,4);
      NickName := trim(Copy(received,1,Pos(#32,received)-1));
      Delete(received,1,Pos(#32,received));
      ResumePosition := received;
      { initialize secondary socket }
      with TClusterServer(Integer(Pointer(TVortexSocket(Sender).Tag))) do
      with FDccFileSource do
           DUPSendFile(FFilename,NickName,StrToInt(ResumePosition),HSocket);
       { end of command }
    end;
    Self.Free;
    { end of socket }
  end;

end;

procedure TPZSocket.OnSocketDisconnected(Sender: TObject; Error: Word);
begin
end;

procedure TPZSocket.OnThreadSendError(Sender: TObject);
begin

end;



end.

