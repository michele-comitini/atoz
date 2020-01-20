
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon SageMaker Runtime
## version: 2017-05-13
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  The Amazon SageMaker runtime API. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sagemaker/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
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
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "runtime.sagemaker.ap-northeast-1.amazonaws.com", "ap-southeast-1": "runtime.sagemaker.ap-southeast-1.amazonaws.com", "us-west-2": "runtime.sagemaker.us-west-2.amazonaws.com", "eu-west-2": "runtime.sagemaker.eu-west-2.amazonaws.com", "ap-northeast-3": "runtime.sagemaker.ap-northeast-3.amazonaws.com", "eu-central-1": "runtime.sagemaker.eu-central-1.amazonaws.com", "us-east-2": "runtime.sagemaker.us-east-2.amazonaws.com", "us-east-1": "runtime.sagemaker.us-east-1.amazonaws.com", "cn-northwest-1": "runtime.sagemaker.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "runtime.sagemaker.ap-south-1.amazonaws.com", "eu-north-1": "runtime.sagemaker.eu-north-1.amazonaws.com", "ap-northeast-2": "runtime.sagemaker.ap-northeast-2.amazonaws.com", "us-west-1": "runtime.sagemaker.us-west-1.amazonaws.com", "us-gov-east-1": "runtime.sagemaker.us-gov-east-1.amazonaws.com", "eu-west-3": "runtime.sagemaker.eu-west-3.amazonaws.com", "cn-north-1": "runtime.sagemaker.cn-north-1.amazonaws.com.cn", "sa-east-1": "runtime.sagemaker.sa-east-1.amazonaws.com", "eu-west-1": "runtime.sagemaker.eu-west-1.amazonaws.com", "us-gov-west-1": "runtime.sagemaker.us-gov-west-1.amazonaws.com", "ap-southeast-2": "runtime.sagemaker.ap-southeast-2.amazonaws.com", "ca-central-1": "runtime.sagemaker.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "runtime.sagemaker.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "runtime.sagemaker.ap-southeast-1.amazonaws.com",
      "us-west-2": "runtime.sagemaker.us-west-2.amazonaws.com",
      "eu-west-2": "runtime.sagemaker.eu-west-2.amazonaws.com",
      "ap-northeast-3": "runtime.sagemaker.ap-northeast-3.amazonaws.com",
      "eu-central-1": "runtime.sagemaker.eu-central-1.amazonaws.com",
      "us-east-2": "runtime.sagemaker.us-east-2.amazonaws.com",
      "us-east-1": "runtime.sagemaker.us-east-1.amazonaws.com",
      "cn-northwest-1": "runtime.sagemaker.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "runtime.sagemaker.ap-south-1.amazonaws.com",
      "eu-north-1": "runtime.sagemaker.eu-north-1.amazonaws.com",
      "ap-northeast-2": "runtime.sagemaker.ap-northeast-2.amazonaws.com",
      "us-west-1": "runtime.sagemaker.us-west-1.amazonaws.com",
      "us-gov-east-1": "runtime.sagemaker.us-gov-east-1.amazonaws.com",
      "eu-west-3": "runtime.sagemaker.eu-west-3.amazonaws.com",
      "cn-north-1": "runtime.sagemaker.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "runtime.sagemaker.sa-east-1.amazonaws.com",
      "eu-west-1": "runtime.sagemaker.eu-west-1.amazonaws.com",
      "us-gov-west-1": "runtime.sagemaker.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "runtime.sagemaker.ap-southeast-2.amazonaws.com",
      "ca-central-1": "runtime.sagemaker.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "runtime.sagemaker"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_InvokeEndpoint_605918 = ref object of OpenApiRestCall_605580
proc url_InvokeEndpoint_605920(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EndpointName" in path, "`EndpointName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/endpoints/"),
               (kind: VariableSegment, value: "EndpointName"),
               (kind: ConstantSegment, value: "/invocations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InvokeEndpoint_605919(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>After you deploy a model into production using Amazon SageMaker hosting services, your client applications use this API to get inferences from the model hosted at the specified endpoint. </p> <p>For an overview of Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p> <p>Amazon SageMaker strips all POST headers except those supported by the API. Amazon SageMaker might add additional headers. You should not rely on the behavior of headers outside those enumerated in the request syntax. </p> <p>Calls to <code>InvokeEndpoint</code> are authenticated by using AWS Signature Version 4. For information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html">Authenticating Requests (AWS Signature Version 4)</a> in the <i>Amazon S3 API Reference</i>.</p> <p>A customer's model containers must respond to requests within 60 seconds. The model itself can have a maximum processing time of 60 seconds before responding to the /invocations. If your model is going to take 50-60 seconds of processing time, the SDK socket timeout should be set to be 70 seconds.</p> <note> <p>Endpoints are scoped to an individual account, and are not public. The URL does not contain the account ID, but Amazon SageMaker determines the account ID from the authentication token that is supplied by the caller.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EndpointName: JString (required)
  ##               : The name of the endpoint that you specified when you created the endpoint using the <a 
  ## href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EndpointName` field"
  var valid_606046 = path.getOrDefault("EndpointName")
  valid_606046 = validateParameter(valid_606046, JString, required = true,
                                 default = nil)
  if valid_606046 != nil:
    section.add "EndpointName", valid_606046
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amzn-SageMaker-Target-Model: JString
  ##                                : Specifies the model to be requested for an inference when invoking a multi-model endpoint. 
  ##   X-Amzn-SageMaker-Custom-Attributes: JString
  ##                                     : Provides additional information about a request for an inference submitted to a model hosted at an Amazon SageMaker endpoint. The information is an opaque value that is forwarded verbatim. You could use this value, for example, to provide an ID that you can use to track a request or to provide other metadata that a service endpoint was programmed to process. The value must consist of no more than 1024 visible US-ASCII characters as specified in <a href="https://tools.ietf.org/html/rfc7230#section-3.2.6">Section 3.3.6. Field Value Components</a> of the Hypertext Transfer Protocol (HTTP/1.1). This feature is currently supported in the AWS SDKs but not in the Amazon SageMaker Python SDK.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   Content-Type: JString
  ##               : The MIME type of the input data in the request body.
  ##   X-Amz-Algorithm: JString
  ##   Accept: JString
  ##         : The desired MIME type of the inference in the response.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606047 = header.getOrDefault("X-Amzn-SageMaker-Target-Model")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amzn-SageMaker-Target-Model", valid_606047
  var valid_606048 = header.getOrDefault("X-Amzn-SageMaker-Custom-Attributes")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amzn-SageMaker-Custom-Attributes", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Signature")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Signature", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Content-Sha256", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Date")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Date", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-Credential")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-Credential", valid_606052
  var valid_606053 = header.getOrDefault("X-Amz-Security-Token")
  valid_606053 = validateParameter(valid_606053, JString, required = false,
                                 default = nil)
  if valid_606053 != nil:
    section.add "X-Amz-Security-Token", valid_606053
  var valid_606054 = header.getOrDefault("Content-Type")
  valid_606054 = validateParameter(valid_606054, JString, required = false,
                                 default = nil)
  if valid_606054 != nil:
    section.add "Content-Type", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Algorithm")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Algorithm", valid_606055
  var valid_606056 = header.getOrDefault("Accept")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "Accept", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-SignedHeaders", valid_606057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606081: Call_InvokeEndpoint_605918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>After you deploy a model into production using Amazon SageMaker hosting services, your client applications use this API to get inferences from the model hosted at the specified endpoint. </p> <p>For an overview of Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p> <p>Amazon SageMaker strips all POST headers except those supported by the API. Amazon SageMaker might add additional headers. You should not rely on the behavior of headers outside those enumerated in the request syntax. </p> <p>Calls to <code>InvokeEndpoint</code> are authenticated by using AWS Signature Version 4. For information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html">Authenticating Requests (AWS Signature Version 4)</a> in the <i>Amazon S3 API Reference</i>.</p> <p>A customer's model containers must respond to requests within 60 seconds. The model itself can have a maximum processing time of 60 seconds before responding to the /invocations. If your model is going to take 50-60 seconds of processing time, the SDK socket timeout should be set to be 70 seconds.</p> <note> <p>Endpoints are scoped to an individual account, and are not public. The URL does not contain the account ID, but Amazon SageMaker determines the account ID from the authentication token that is supplied by the caller.</p> </note>
  ## 
  let valid = call_606081.validator(path, query, header, formData, body)
  let scheme = call_606081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606081.url(scheme.get, call_606081.host, call_606081.base,
                         call_606081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606081, url, valid)

proc call*(call_606152: Call_InvokeEndpoint_605918; EndpointName: string;
          body: JsonNode): Recallable =
  ## invokeEndpoint
  ## <p>After you deploy a model into production using Amazon SageMaker hosting services, your client applications use this API to get inferences from the model hosted at the specified endpoint. </p> <p>For an overview of Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p> <p>Amazon SageMaker strips all POST headers except those supported by the API. Amazon SageMaker might add additional headers. You should not rely on the behavior of headers outside those enumerated in the request syntax. </p> <p>Calls to <code>InvokeEndpoint</code> are authenticated by using AWS Signature Version 4. For information, see <a href="http://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html">Authenticating Requests (AWS Signature Version 4)</a> in the <i>Amazon S3 API Reference</i>.</p> <p>A customer's model containers must respond to requests within 60 seconds. The model itself can have a maximum processing time of 60 seconds before responding to the /invocations. If your model is going to take 50-60 seconds of processing time, the SDK socket timeout should be set to be 70 seconds.</p> <note> <p>Endpoints are scoped to an individual account, and are not public. The URL does not contain the account ID, but Amazon SageMaker determines the account ID from the authentication token that is supplied by the caller.</p> </note>
  ##   EndpointName: string (required)
  ##               : The name of the endpoint that you specified when you created the endpoint using the <a 
  ## href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API. 
  ##   body: JObject (required)
  var path_606153 = newJObject()
  var body_606155 = newJObject()
  add(path_606153, "EndpointName", newJString(EndpointName))
  if body != nil:
    body_606155 = body
  result = call_606152.call(path_606153, nil, nil, nil, body_606155)

var invokeEndpoint* = Call_InvokeEndpoint_605918(name: "invokeEndpoint",
    meth: HttpMethod.HttpPost, host: "runtime.sagemaker.amazonaws.com",
    route: "/endpoints/{EndpointName}/invocations",
    validator: validate_InvokeEndpoint_605919, base: "/", url: url_InvokeEndpoint_605920,
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
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
