
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AmazonApiGatewayManagementApi
## version: 2018-11-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## The Amazon API Gateway Management API allows you to directly manage runtime aspects of your deployed APIs. To use it, you must explicitly set the SDK's endpoint to point to the endpoint of your deployed API. The endpoint will be of the form https://{api-id}.execute-api.{region}.amazonaws.com/{stage}, or will be the endpoint corresponding to your API's custom domain and base path, if applicable.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/execute-api/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                       default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
                                                            ## a suitable default value when appropriate
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Https: {"ap-northeast-1": "execute-api.ap-northeast-1.amazonaws.com", "ap-southeast-1": "execute-api.ap-southeast-1.amazonaws.com", "us-west-2": "execute-api.us-west-2.amazonaws.com", "eu-west-2": "execute-api.eu-west-2.amazonaws.com", "ap-northeast-3": "execute-api.ap-northeast-3.amazonaws.com", "eu-central-1": "execute-api.eu-central-1.amazonaws.com", "us-east-2": "execute-api.us-east-2.amazonaws.com", "us-east-1": "execute-api.us-east-1.amazonaws.com", "cn-northwest-1": "execute-api.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "execute-api.ap-south-1.amazonaws.com", "eu-north-1": "execute-api.eu-north-1.amazonaws.com", "ap-northeast-2": "execute-api.ap-northeast-2.amazonaws.com", "us-west-1": "execute-api.us-west-1.amazonaws.com", "us-gov-east-1": "execute-api.us-gov-east-1.amazonaws.com", "eu-west-3": "execute-api.eu-west-3.amazonaws.com", "cn-north-1": "execute-api.cn-north-1.amazonaws.com.cn", "sa-east-1": "execute-api.sa-east-1.amazonaws.com", "eu-west-1": "execute-api.eu-west-1.amazonaws.com", "us-gov-west-1": "execute-api.us-gov-west-1.amazonaws.com", "ap-southeast-2": "execute-api.ap-southeast-2.amazonaws.com", "ca-central-1": "execute-api.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "execute-api.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "execute-api.ap-southeast-1.amazonaws.com",
      "us-west-2": "execute-api.us-west-2.amazonaws.com",
      "eu-west-2": "execute-api.eu-west-2.amazonaws.com",
      "ap-northeast-3": "execute-api.ap-northeast-3.amazonaws.com",
      "eu-central-1": "execute-api.eu-central-1.amazonaws.com",
      "us-east-2": "execute-api.us-east-2.amazonaws.com",
      "us-east-1": "execute-api.us-east-1.amazonaws.com",
      "cn-northwest-1": "execute-api.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "execute-api.ap-south-1.amazonaws.com",
      "eu-north-1": "execute-api.eu-north-1.amazonaws.com",
      "ap-northeast-2": "execute-api.ap-northeast-2.amazonaws.com",
      "us-west-1": "execute-api.us-west-1.amazonaws.com",
      "us-gov-east-1": "execute-api.us-gov-east-1.amazonaws.com",
      "eu-west-3": "execute-api.eu-west-3.amazonaws.com",
      "cn-north-1": "execute-api.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "execute-api.sa-east-1.amazonaws.com",
      "eu-west-1": "execute-api.eu-west-1.amazonaws.com",
      "us-gov-west-1": "execute-api.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "execute-api.ap-southeast-2.amazonaws.com",
      "ca-central-1": "execute-api.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "apigatewaymanagementapi"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_PostToConnection_402656481 = ref object of OpenApiRestCall_402656038
proc url_PostToConnection_402656483(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
                 (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostToConnection_402656482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sends the provided data to the specified connection.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   connectionId: JString (required)
                                 ##               : The identifier of the connection that a specific client is using.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `connectionId` field"
  var valid_402656484 = path.getOrDefault("connectionId")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "connectionId", valid_402656484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656485 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Security-Token", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Signature")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Signature", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Algorithm", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Date")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Date", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Credential")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Credential", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656493: Call_PostToConnection_402656481;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends the provided data to the specified connection.
                                                                                         ## 
  let valid = call_402656493.validator(path, query, header, formData, body, _)
  let scheme = call_402656493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656493.makeUrl(scheme.get, call_402656493.host, call_402656493.base,
                                   call_402656493.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656493, uri, valid, _)

proc call*(call_402656494: Call_PostToConnection_402656481;
           connectionId: string; body: JsonNode): Recallable =
  ## postToConnection
  ## Sends the provided data to the specified connection.
  ##   connectionId: string (required)
                                                         ##               : The identifier of the connection that a specific client is using.
  ##   
                                                                                                                                             ## body: JObject (required)
  var path_402656495 = newJObject()
  var body_402656496 = newJObject()
  add(path_402656495, "connectionId", newJString(connectionId))
  if body != nil:
    body_402656496 = body
  result = call_402656494.call(path_402656495, nil, nil, nil, body_402656496)

var postToConnection* = Call_PostToConnection_402656481(
    name: "postToConnection", meth: HttpMethod.HttpPost,
    host: "execute-api.amazonaws.com", route: "/@connections/{connectionId}",
    validator: validate_PostToConnection_402656482, base: "/",
    makeUrl: url_PostToConnection_402656483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetConnection_402656290(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
                 (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnection_402656289(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get information about the connection with the provided id.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   connectionId: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `connectionId` field"
  var valid_402656380 = path.getOrDefault("connectionId")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "connectionId", valid_402656380
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656381 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Security-Token", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Signature")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Signature", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Algorithm", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Date")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Date", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Credential")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Credential", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656401: Call_GetConnection_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get information about the connection with the provided id.
                                                                                         ## 
  let valid = call_402656401.validator(path, query, header, formData, body, _)
  let scheme = call_402656401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656401.makeUrl(scheme.get, call_402656401.host, call_402656401.base,
                                   call_402656401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656401, uri, valid, _)

proc call*(call_402656450: Call_GetConnection_402656288; connectionId: string): Recallable =
  ## getConnection
  ## Get information about the connection with the provided id.
  ##   connectionId: string (required)
  var path_402656451 = newJObject()
  add(path_402656451, "connectionId", newJString(connectionId))
  result = call_402656450.call(path_402656451, nil, nil, nil, nil)

var getConnection* = Call_GetConnection_402656288(name: "getConnection",
    meth: HttpMethod.HttpGet, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_GetConnection_402656289,
    base: "/", makeUrl: url_GetConnection_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_402656497 = ref object of OpenApiRestCall_402656038
proc url_DeleteConnection_402656499(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
                 (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConnection_402656498(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete the connection with the provided id.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   connectionId: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `connectionId` field"
  var valid_402656500 = path.getOrDefault("connectionId")
  valid_402656500 = validateParameter(valid_402656500, JString, required = true,
                                      default = nil)
  if valid_402656500 != nil:
    section.add "connectionId", valid_402656500
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656501 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Security-Token", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Signature")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Signature", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Algorithm", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Date")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Date", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Credential")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Credential", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656508: Call_DeleteConnection_402656497;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete the connection with the provided id.
                                                                                         ## 
  let valid = call_402656508.validator(path, query, header, formData, body, _)
  let scheme = call_402656508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656508.makeUrl(scheme.get, call_402656508.host, call_402656508.base,
                                   call_402656508.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656508, uri, valid, _)

proc call*(call_402656509: Call_DeleteConnection_402656497; connectionId: string): Recallable =
  ## deleteConnection
  ## Delete the connection with the provided id.
  ##   connectionId: string (required)
  var path_402656510 = newJObject()
  add(path_402656510, "connectionId", newJString(connectionId))
  result = call_402656509.call(path_402656510, nil, nil, nil, nil)

var deleteConnection* = Call_DeleteConnection_402656497(
    name: "deleteConnection", meth: HttpMethod.HttpDelete,
    host: "execute-api.amazonaws.com", route: "/@connections/{connectionId}",
    validator: validate_DeleteConnection_402656498, base: "/",
    makeUrl: url_DeleteConnection_402656499,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}