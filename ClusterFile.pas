unit ClusterFile;

interface

uses
  SysUtils, Classes, VortexCommon,
  {$IFDEF MSWINDOWS}
  Messages, Controls, wsocket, winsock, extctrls, windows;
  {$ELSE}
  QControls;
  {$ENDIF}

const
 BufferSize = 4095;

Type TPacketSize = (ps512  = 511,         ps1024 = 1023,
                    ps2048 = 2047,        ps4096 = 4095,
                    ps8192 = 8191);

type TEventType  = ( etNone,              etDeleteThread,
                     etDisconnect,        etConnected,
                     etTimeOut,           etIncomplete,
                     etCompleted,         etProgress);

type
   TComponentReady  = procedure (sender : TObject) of object;
   TSendIncomplete  = procedure (Sender : TObject; Filename,BytesSent,TotalFileSize : string) of object;
   TSendConnected   = function  (Sender : TObject; FileName,Filesize : string) : integer of object;
   TSendProgress    = procedure (Sender : TObject; Filename : string;BytesSent,TotalFileSize,Progress : integer) of object;
   TSendFileDone    = procedure (Sender : TObject; Filename,TotalSent : string) of object;
   TGetIncomplete   = procedure (Sender : TObject; Filename,TotalReceived,TotalFileSize : string) of object;
   TGetConnected    = function  (Sender : TObject; FileName,Filesize : string) : Integer of object;
   TGetProgress     = procedure (Sender : TObject; Filename : string;BytesReceived,TotalFileSize,Progress : integer) of object;
   TGetFileDone     = procedure (Sender : TObject; Filename,TotalReceived,TotalFileSize : string) of object;
   TGetDisconnected = procedure (sender : TObject; Nickname, Filename : string) of object;

  type
    TSocksOptions = class(TPersistent)
  private
  {$IFDEF MSWINDOWS}
      FSocksAuthentication : TSocksAuthentication;
  {$ENDIF}
    FSocksPassword       : string;
    FSocksUserCode       : string;
    FSocksServer         : string;
    FSocksLevel          : string;
    FSocksPort           : string;
  published
  {$IFDEF MSWINDOWS}
      property SocksAuthentication : TSocksAuthentication read FSocksAuthentication write FSocksAuthentication;
  {$ENDIF}
    property SocksPassword  : string read FSocksPassword write FSocksPassword;
    property SocksUserCode  : string read FSocksUserCode write FSocksUserCOde;
    property SocksServer    : string read FSocksServer   write FSocksServer;
    property SocksLevel     : string read FSocksLevel    write FSocksLevel;
    property SocksPort      : string read FSocksPort     write FSocksPort;
  end;

  type
    TDccOptions = class(TPersistent)
  private
    FDefaultGetdir : string;
    FNickAsFolder  : boolean;
    FChecksums     : boolean;
    FPacketSize    : TPacketSize;
  published
    property ClusterPacketSize        : TPacketSize read FPacketSize  write FPacketSize;
    property ClusterDefaultGetPath    : string  read FDefaultGetdir write FDefaultGetdir;
    property ClusterNicknameAsFolder  : boolean read FNickAsFolder  write FNickAsFolder;
    property ClustermIRCChecksums     : boolean read FChecksums     write FChecksums;
  end;

type
  TClusterFile = class(TComponent)
  private
    FGetDisconnected    : TGetDisconnected;
    FDccSockOptions     : TSocksOptions;
    FSendIncomplete     : TSendIncomplete;
    FComponentReady     : TComponentReady;
    FSendConnected      : TSendConnected;
    FGetIncomplete      : TGetIncomplete;
    FGetConnected       : TGetConnected;
    FSendProgress       : TSendProgress;
    FSendFileDone       : TSendFileDone;
    FGetProgress        : TGetProgress;
    FGetFileDone        : TGetFileDone;
    FPacketSize         : TPacketSize;
    FDccOptions         : TDccOptions;
    FDccList            : TStringList;
    FTempFileSize       : string;
    FAutoID             : integer;
    procedure SetDccSocksOptions(const Value: TSocksOptions);
    procedure SetDccOptions(const Value: TDccOptions);
  protected
    procedure Loaded; override;
  public
    constructor Create  (AOwner : TComponent); override;
    destructor destroy; override;
    { used to listen for a connection }
    function  InitThreadSend(FileName: string; nickname : string = '';ResumePosition : Int64 = 0;Listenport : Integer = 0) : string;
    procedure ThreadSendfile(Hostname,Remoteport,Filepath,Filename : string);
    function  ThreadGetFile(AFileName: string;ARemoteHost,ARemotePort,AFileSize : string; ANickName : string = '';AResumePos : Int64 = 0) : string;

    { These functions are used by Cluster file component }
    function DUPGetFile(AFileName, AFileSize,  Anickname: string; AResumePos : Int64; ADupSocket: Integer): string;
    function  DUPSendFile(FileName: string; nickname : string = '';ResumePosition : Int64 = 0;DupSocket : Integer = -1) : string;

  published
    property TemporaryFilesize : string        read FTempFileSize   write FTempFileSize;
    property DccOptions        : TDccOptions   read FDccOptions     write SetDccOptions;
    property SocksOptions      : TSocksOptions read FDccSockOptions write SetDccSocksOptions;
    { events }
    property OnComponentReady : TComponentReady read FComponentReady write FComponentReady;
    property OnGetFileDone    : TGetFileDone    read FGetFileDone    write FGetFileDone;
    property OnSendFileDone   : TSendFileDone   read FSendFileDone   write FSendFileDone;
    property OnSendConnected  : TSendConnected  read FSendConnected  write FSendConnected;
    property OnGetConnected   : TGetConnected   read FGetConnected   write FGetConnected;
    property OnGetProgress    : TGetProgress    read FGetProgress    write FGetProgress;
    property OnSendProgress   : TSendProgress   read FSendProgress   write FSendProgress;
    property OnGetIncomplete  : TGetIncomplete  read FGetIncomplete  write FGetIncomplete;
    property OnSendIncomplete : TSendIncomplete read FSendIncomplete write FSendIncomplete;
    property OnClientDisconnected : TGetDisconnected read FGetDisconnected write FGetDisconnected;
end;


type
  TDccGet         = class(TThread)
  private
    FCustomSocket  : TVortexSocket;
    FCustomFile    : TFileStream;
    FMainThread    : TClusterFile;
    FEventType     : TEventType;
    FPacketSize    : TPacketSize;
    FGetFromNick   : string;
    FGetFilename   : string;
    FGetFilePath   : string;
    FGetFileSize   : Int64;
    procedure DoMessages;
  protected
    procedure OnThreadGetDisconnected(Sender: TObject; Error: Word);
    procedure OnThreadGetDataAvailable(Sender: TObject; Error: Word);
    procedure OnThreadGetConnect(Sender: TObject; Error: Word);
    procedure Execute; override;
  published
    property DccGetFileName  : string read FGetFileName write FGetFileName;
    property DccGetPath      : string read FGetFilePath write FGetFilePath;
    property DccGetNick      : string read FGetFromNick write FGetFromNick;
    property DccGetFileSize  : int64  read FGetFileSize write FGetFileSize;
  end;


type
  TDccSend = class(TThread)
  private
    FMainThread    : TClusterFile;
    FEventType     : TEventType;
    FPacketSize    : TPacketSize;
    FCustomSocket  : TVortexSocket;
    FCustomFile    : TFileStream;
    FSockPort      : string;
    FSockAddress   : string;
    FSendToNick    : string;
    FSendFilename  : string;
    FSendFilePath  : string;
    FSendFileSize  : Int64;
  protected
    procedure OnThreadSendDisconnected(Sender: TObject; Error: Word);
    procedure OnThreadSendConnect(Sender: TObject; Error: Word);
    procedure OnThreadSendError(Sender: TObject);
    procedure Execute; override;
    procedure DoMessages;

  published
    property SendFileName : string read FSendFilename write FSendFilename;
    property SendFileSize : Int64 read FSendFileSize write FSendFileSize;
    property SendFilePath : string read FSendFilePath write FSendFilePath;
    property SendNickname : string read FSendToNick write FSendToNick;
    property SendAddress  : string read FSockAddress write FSockAddress;
    property SendPort     : string read FSockPort write FSockPort;
end;

procedure Register;
implementation

procedure Register;
begin
  RegisterComponents('joepezT', [TClusterFile]);
end;

function percent (Received,TotalSize : int64) : integer;
begin
  result :=  round(received * 100 / TotalSize);
end;

function hton(v: cardinal): cardinal;
begin
  result  := (v  shr 24)    or
             ((v shr 8)     and $ff00) or
             ((v and $ff00) shl 8)     or
             ((v and $ff)   shl 24);
end;


procedure TClusterFile.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in ComponentState) then
  if Assigned(FComponentReady) then
  FComponentReady(self);
end;


constructor TClusterFile.Create(AOwner: TComponent);
begin
  inherited Create(Aowner);
  FDccSockOptions := TSocksOptions.Create;
  FDccOptions := TDccOptions.create;
  FDccList := TStringList.create;
  with (FDccSockOptions) do
  if (FSocksPassword = '') then
      FSocksPassword := '5';
end;

destructor TClusterFile.destroy;
begin
  FreeAndNil(FDccList);
  inherited;
end;

function  TClusterFile.InitThreadSend(FileName: string; nickname : string = '';ResumePosition : Int64 = 0;Listenport : Integer = 0) : string;
var
ListeningSock : TVortexSocket;
Thread        : TDccSend;

begin
    Thread := TDccSend.Create(true);
    with Thread do
    begin
      FMainThread := Self;
      FSendFilename := ExtractFileName(FileName);
      FSendFilePath := ExtractFilePath(filename);

      begin
        if FSendFilePath[Length(FSendFilePath)] <> '\'  then
        FSendFilePath := FSendFilePath + '\';
      end;

      if not FileExists(filename) then
      begin
        result := '-1';
        exit;
      end;

      ListeningSock := TVortexSocket.Create(self);
      with ListeningSock do
      try
        FCustomFile := TFileStream.Create(filename,fmShareDenyWrite);
        with FCustomFile do
        begin
          Seek(ResumePosition,soFromBeginning);
          SendFileSize := Size;
          { will remove this later }
          FTempFileSize := IntToStr(Size);
        end;

        OnSessionAvailable := OnThreadSendConnect;
        OnSessionClosed    := OnThreadSendDisconnected;

        Addr := '0.0.0.0';
        port := IntToStr(Listenport);
        listen;
        { Get the port assigned by winsock }
         result := GetXPort;

      except
        DeleteObjects(ListeningSock);
        result := '-1';
        Terminate;
      end;
    end;
end;

Procedure TClusterFile.ThreadSendFile(Hostname, Remoteport, Filepath,
  Filename: string);
var
NewThread : TDccSend;

begin
  NewThread := TDccSend.Create(True);

  with NewThread do
  begin
    FSendFilename := Filename;
    FSendFilePath := Filepath;
    FMainThread   := self;

    with FCustomSocket do
    try
      OnSessionConnected := OnThreadSendConnect;
      OnSessionClosed := OnThreadSendDisconnected;
      OnError         := OnThreadSendError;
      FCustomFile := TFileStream.Create(FileName,fmShareDenyWrite);
      tag  := Integer(Pointer(NewThread));
      Addr := Hostname;
      port := RemotePort;
      connect;
    except
      { oops }
    end
  end;
end;


function  TClusterFile.DupSendFile(FileName: string; nickname : string = '';ResumePosition : Int64 = 0;DupSocket : Integer = -1) : string;
var
Thread        : TDccSend;

begin
  Thread := TDccSend.Create(true);
  with Thread do
  with FDccOptions do
  begin
    { set pointer to the main component }
    FMainThread := Self;
    { some file info }
    FSendFilename := ExtractFileName(FileName);
    FSendFilePath := FDefaultGetdir;

    if FSendFilePath <> '' then
    begin
      if FSendFilePath[Length(FSendFilePath)] <> '\'  then
      FSendFilePath := FSendFilePath + '\';
    end else FSendFilePath := 'c:\';

    { does the file exist... }
    if not FileExists(filename) then
    begin
      result := '-1';
      exit;
    end;

    FCustomSocket := TVortexSocket.Create(self);
    with FCustomSocket do
    begin
      FCustomFile := TFileStream.Create(filename,fmShareDenyWrite);
      with FCustomFile do
      begin
        Seek(ResumePosition,soFromBeginning);
        FSendFileSize := Size;
      end;
      OnSessionClosed    := OnThreadSendDisconnected;
      Dup(dupsocket);
    end;
    Resume;
  end;
end;

procedure TDccSend.DoMessages;
var
i : integer;

begin
  with TClusterFile(FMainThread) do
  try
    try
      case (FEventType) of
        etProgress:
        with FCustomFile do
        begin
          if (FSendFileSize <> 0) then
          i := Percent(Position,FSendFileSize);

          If Assigned(FGetProgress) then
          FSendProgress(Self, FSendFilename, Position, FsendFileSize, i);
        end;

        { triggers when we are connected }
        etConnected:
        begin
          if Assigned(FSendConnected) then
          FSendConnected(self,FSendFilename,IntToStr(FSendFileSize));
        end;

        { triggers when disconnected }
        etDisconnect:
        begin
       {   if Assigned(FSendDisconnected) then
          FSendDis(self,FSendToNick, FGetFilename);    }
        end;

        etCompleted:
        begin
          if Assigned(FSendFileDone) then
          with (FCustomFile) do
          FSendFileDone(Self,FSendFilename,IntToStr(Position));
        end;

        etIncomplete:
        begin
          if Assigned(FSendIncomplete) then
          with (FCustomFile) do
          FSendIncomplete(self,FSendFilename,IntToStr(Size),IntToStr(FSendFileSize));
        end;

        etTimeOut:
        begin
          { NOTHING here yet }
        end;

       { when the thread is finished, it's a good idea to remove it from the list }
       etDeleteThread:
       with FDccList do
       begin
         if (FCustomSocket <> nil) then DeleteObjects(FCustomSocket);
         i := IndexOf(IntToStr(tag));
         if (i <> -1) then Delete(i);
       end;
       { end of case statement }
      end;
    except
      { some error }
{      if assigned(FChatException) then
      FChatException(self)}
    end;

  finally
    if (self <> nil) then
    begin
      FEventType   := etNone;
    end;
  end;

end;

procedure TDccSend.Execute;
var
Buffer       : array [0..BufferSize] of Char;
BufferLength : integer;

begin
  try
    while (Bufferlength <> 0) or
          (not terminated) do
    begin
      with FCustomFile do
      BufferLength := Read(Buffer, sizeof(Buffer));

      with FCustomSocket do
      if (FCustomSocket.State <> wsClosed) then
      begin
        Send(@Buffer, BufferLength);
      {$IFDEF MSWINDOWS}
        Flush;
      {$ENDIF}
      end else
      Break;
      
      { fire event progress }
      FEventType := etProgress;
      Synchronize(DoMessages);
    end;
      { end of socket operations }
  finally
    if (FSendFileSize <> FCustomFile.Size) then
    begin
      FEventType := etIncomplete;
      Synchronize(DoMessages);
    end else
    begin { if (FGetFileSize = FCustomFile.Size) then }
      FEventType := etCompleted;
      Synchronize(DoMessages);
    end;

    FEventType := etDeleteThread;
    Synchronize(DoMessages);
  end;
end;

procedure TDccSend.OnThreadSendConnect(Sender: TObject; Error: Word);
var
Socket : TVortexSocket;

begin
  socket := TVortexSocket(Sender);
  FCustomSocket := TVortexSocket.Create(nil);
  with FCustomSocket do
  begin
    OnSessionClosed := OnThreadSendDisconnected;
    OnError := OnThreadSendError;
    HSocket         := socket.Accept;

    { Event trigger}
    with TClusterFile(FMainThread) do
    begin
      if Assigned(FSendConnected) then
      with FCustomFile do
      FSendConnected(Self,FSendFilename,IntToStr(FSendFileSize));
    end;

    DeleteObjects(Socket);
  end;
  Resume;
end;

procedure TDccSend.OnThreadSendDisconnected(Sender: TObject; Error: Word);
begin
  terminate
end;

procedure TDccSend.OnThreadSendError(Sender: TObject);
begin
  terminate
end;

procedure TClusterFile.SetDccSocksOptions(const Value: TSocksOptions);
begin
  FDccSockOptions.Assign(Value);
end;


procedure TClusterFile.SetDccOptions(const Value: TDccOptions);
begin
  FDccOptions.Assign(Value);
end;

procedure TDccGet.DoMessages;
var
i : integer;

begin
  with TClusterFile(FMainThread) do
  try
    try
      case (FEventType) of
        etProgress:
        with FCustomFile do
        begin
          if (FGetFileSize <> 0) then
          i := Percent(Position,FGetFileSize);

          If Assigned(FGetProgress) then
          FGetProgress(Self, FGetFilename, Position, FGetFileSize, i);
        end;

        { triggers when we are connected }
        etConnected:
        begin
          if Assigned(FGetConnected) then
          FGetConnected(self,FGetFilename,IntToStr(FGetFileSize));
        end;

        { triggers when disconnected }
        etDisconnect:
        begin
          if Assigned(FGetDisconnected) then
          FGetDisconnected(self,FGetFromNick, FGetFilename);
        end;

        etCompleted:
        begin
          if Assigned(FGetFileDone) then
          with (FCustomFile) do
          FGetFileDone(Self,FGetFilename,IntToStr(Size),IntToStr(FGetFileSize));
        end;

        etIncomplete:
        begin
          if Assigned(FGetIncomplete) then
          with (FCustomFile) do
          FGetIncomplete(Self,FGetFilename,IntToStr(Size),IntToStr(FGetFileSize));
        end;

        etTimeOut:
        begin
          { NOTHING here yet }
        end;

       { when the thread is finished, it's a good idea to remove it from the list }
       etDeleteThread:
       with FDccList do
       begin
         if (FCustomSocket <> nil) then DeleteObjects(FCustomSocket);
         i := IndexOf(IntToStr(tag));
         if (i <> -1) then Delete(i);
       end;
       { end of case statement }
      end;
    except
      { some error }
{      if assigned(FChatException) then
      FChatException(self)}
    end;

  finally
    if (self <> nil) then
    begin
      FEventType   := etNone;
    end;
  end;
end;


{ DCC Get routines }
{ DCC Get routines }{ DCC Get routines }
{ DCC Get routines }{ DCC Get routines }{ DCC Get routines }
{ DCC Get routines }{ DCC Get routines }{ DCC Get routines }{ DCC Get routines }
procedure TDccGet.Execute;
begin
  { just a loop }
  while (not Terminated) and
        (FCustomSocket.State <> wsClosed) do
        Sleep(1);

  if (FGetFileSize <> FCustomFile.Size) then
  begin
    FEventType := etIncomplete;
    Synchronize(DoMessages);
  end else
  begin { if (FGetFileSize = FCustomFile.Size) then }
    FEventType := etCompleted;
    Synchronize(DoMessages);
  end;

  FEventType := etDeleteThread;
  Synchronize(DoMessages);
end;

procedure TDccGet.OnThreadGetDisconnected(Sender: TObject;  Error: Word);
begin
  FEventType := etDisconnect;
  Synchronize(DoMessages);
end;

procedure TDccGet.OnThreadGetConnect(Sender: TObject; Error: Word);
begin
  with FCustomFile do
  begin
    FEventType := etConnected;
    Synchronize(DoMessages);
    resume;
  end;
end;

procedure TDccGet.OnThreadGetDataAvailable(Sender: TObject; Error: Word);
var
   ASocket      : TVortexSocket;
   ASize        : cardinal;
   completed    : Byte;
   BufLen       : Int64;
   SocketBuffer : array [0..BufferSize] Of Byte;
   ACrc         : string;

begin
  ASocket := TVortexSocket(sender);

  with TClusterFile(FMainThread) do
  begin
    BufLen := ASocket.Receive(@SocketBuffer, sizeof(SocketBuffer));
    FCustomFile.write(SocketBuffer,BufLen);

    { Progress Event }
    with FCustomFile do
    begin
      FEventType := etProgress;
      Synchronize(DoMessages);

      { checksum clients like mIRC is expecting }
      if (FDccOptions.FChecksums) then
      begin
        ASize := hton(FCustomFile.Size);
        sleep(20);
        ASocket.Send(@ASize, sizeof(Asize));
      end;
    end;
  { end of progress }
  end;
{  finally
    if assigned(Asocket) then
    ASocket.Flush;
  end;}
end;

{ Filename | Remotehost | | Remoteport | Filesize | nickname | resume position }
function  TClusterFile.ThreadGetFile(AFileName: string; ARemoteHost, ARemotePort, AFileSize : string; ANickName : string = '';AResumePos : Int64 = 0) : string;
var
DccGet      : TDccGet;
FileAndPath : string;
Folders     : string;

begin
  DccGet := TDccGet.Create(true);
  with DccGet do
  begin
    tag := StrToInt(ARemotePort);
    with FDccList do
    begin
      inc(FAutoID);
      AddObject(IntToStr(FAutoID),DccGet);
    end;

    FMainThread  := self;
    FGetFilename := ExtractFileName(AFileName);

    FGetFileSize  := StrToInt(AFileSize);
    FTempFileSize := DccGetFileName;

    { Filepath stuff }
    if FdccOptions.FDefaultGetdir <> '' then
    begin
      with FDccOptions do
      begin
        Folders := FDefaultGetdir;
        if Folders[Length(Folders)] <> '\'  then
        Folders := Folders + '\';

        if (not DirectoryExists(folders)) then
        MkDir(Folders);
        FileAndPath := Folders + FGetFilename;

        if FNickAsFolder then
        begin
          folders := folders + ANickName + '\';
          if (not DirectoryExists(folders)) then
          MkDir(Folders);
          FileAndPath := Folders + FGetFilename;
        end;
      end;
    end else FileAndPath := 'c:\' + FGetFilename;

    { check wether file exists or not... }
    if (not FileExists(FileAndPath)) then
    begin
      { need to do something with the resume case }
      FCustomFile := TFileStream.Create(FileAndPath,fmCreate);
      FCustomFile.Seek(AResumePos,soFromBeginning);
    end else
    begin
      { do some resume stuff here }
      FCustomFile := TFileStream.Create(FileAndPath,fmShareDenyNone);
      FCustomFile.Seek(AResumePos,soFromBeginning);
    end;

    { socket stuff }
    FCustomSocket := TVortexSocket.Create(FCustomSocket);
    with FCustomSocket do
    begin
      OnSessionConnected := OnThreadGetConnect;
      OnSessionClosed    := OnThreadGetDisconnected;
      OnDataAvailable    := OnThreadGetDataAvailable;

      with FDccSockOptions do
      begin
        SocksPort     := FsocksPort;
        SocksServer   := FSocksServer;
        Sockspassword := FSocksPassword;
      end;
      BufSize := BufferSize;
      Addr := ARemoteHost;
      port := ARemotePort;
      connect;

    end;
  { thread }
  end;

end;

{ this one is used by Cluster server }
function TClusterFile.DUPGetFile(AFileName, AFileSize,  Anickname: string; AResumePos : Int64; ADupSocket: Integer): string;
var
DccServerGet : TDccGet;
FileAndPath  : string;
temp         : string;
folders      : string;

begin
  DccServerGet := TDccGet.Create(true);

  with DccServerGet do
  with FDccOptions do
  begin
    FMainThread := self;

    { some file thignies }
    FGetFilename  := ExtractFileName(AFileName);
    FGetFileSize  := StrToInt(AFileSize);
    FTempFileSize := AFileSize;

    { Filepath stuff }
    if FdccOptions.FDefaultGetdir <> '' then
    begin
      with FDccOptions do
      begin
        Folders := FDefaultGetdir;
        if Folders[Length(Folders)] <> '\'  then
        Folders := Folders + '\';

        if (not DirectoryExists(folders)) then
        MkDir(Folders);
        FileAndPath := Folders + FGetFilename;

        if FNickAsFolder then
        begin
          folders := folders + ANickName + '\';
          if (not DirectoryExists(folders)) then
          MkDir(Folders);
          FileAndPath := Folders + FGetFilename;
        end;
      end;
    end else FileAndPath := 'c:\' + FGetFilename;

    { check wether file exists or not... }
    if (not FileExists(FileAndPath)) then
    begin
      { need to do something with the resume case }
      FCustomFile := TFileStream.Create(FileAndPath,fmCreate);
      FCustomFile.Seek(AResumePos,soFromBeginning);
    end else
    begin
      { do some resume stuff here }
      FCustomFile := TFileStream.Create(FileAndPath,fmShareDenyNone);
      FCustomFile.Seek(AResumePos,soFromBeginning);
    end;

    FCustomSocket := TVortexSocket.Create(FCustomSocket);
    with FCustomSocket do
    begin
      OnDataAvailable    := OnThreadGetDataAvailable;
      OnSessionClosed    := OnThreadGetDisconnected;
      Resume;
      Dup(ADupSocket);
    end;

    { adds all to a thread }
    tag := StrToInt(FCustomSocket.GetPeerPort);
    with FDccList do
    begin
      inc(FAutoID);
      AddObject(IntToStr(FAutoID),DccServerGet);
    end;

  end
end;


end.
