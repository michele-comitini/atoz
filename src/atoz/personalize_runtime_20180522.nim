
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Personalize Runtime
## version: 2018-05-22
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p/>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/personalize-runtime/
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
              path: JsonNode): string

  OpenApiRestCall_772588 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772588](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772588): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "personalize-runtime.ap-northeast-1.amazonaws.com", "ap-southeast-1": "personalize-runtime.ap-southeast-1.amazonaws.com", "us-west-2": "personalize-runtime.us-west-2.amazonaws.com", "eu-west-2": "personalize-runtime.eu-west-2.amazonaws.com", "ap-northeast-3": "personalize-runtime.ap-northeast-3.amazonaws.com", "eu-central-1": "personalize-runtime.eu-central-1.amazonaws.com", "us-east-2": "personalize-runtime.us-east-2.amazonaws.com", "us-east-1": "personalize-runtime.us-east-1.amazonaws.com", "cn-northwest-1": "personalize-runtime.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "personalize-runtime.ap-south-1.amazonaws.com", "eu-north-1": "personalize-runtime.eu-north-1.amazonaws.com", "ap-northeast-2": "personalize-runtime.ap-northeast-2.amazonaws.com", "us-west-1": "personalize-runtime.us-west-1.amazonaws.com", "us-gov-east-1": "personalize-runtime.us-gov-east-1.amazonaws.com", "eu-west-3": "personalize-runtime.eu-west-3.amazonaws.com", "cn-north-1": "personalize-runtime.cn-north-1.amazonaws.com.cn", "sa-east-1": "personalize-runtime.sa-east-1.amazonaws.com", "eu-west-1": "personalize-runtime.eu-west-1.amazonaws.com", "us-gov-west-1": "personalize-runtime.us-gov-west-1.amazonaws.com", "ap-southeast-2": "personalize-runtime.ap-southeast-2.amazonaws.com", "ca-central-1": "personalize-runtime.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "personalize-runtime.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "personalize-runtime.ap-southeast-1.amazonaws.com",
      "us-west-2": "personalize-runtime.us-west-2.amazonaws.com",
      "eu-west-2": "personalize-runtime.eu-west-2.amazonaws.com",
      "ap-northeast-3": "personalize-runtime.ap-northeast-3.amazonaws.com",
      "eu-central-1": "personalize-runtime.eu-central-1.amazonaws.com",
      "us-east-2": "personalize-runtime.us-east-2.amazonaws.com",
      "us-east-1": "personalize-runtime.us-east-1.amazonaws.com",
      "cn-northwest-1": "personalize-runtime.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "personalize-runtime.ap-south-1.amazonaws.com",
      "eu-north-1": "personalize-runtime.eu-north-1.amazonaws.com",
      "ap-northeast-2": "personalize-runtime.ap-northeast-2.amazonaws.com",
      "us-west-1": "personalize-runtime.us-west-1.amazonaws.com",
      "us-gov-east-1": "personalize-runtime.us-gov-east-1.amazonaws.com",
      "eu-west-3": "personalize-runtime.eu-west-3.amazonaws.com",
      "cn-north-1": "personalize-runtime.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "personalize-runtime.sa-east-1.amazonaws.com",
      "eu-west-1": "personalize-runtime.eu-west-1.amazonaws.com",
      "us-gov-west-1": "personalize-runtime.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "personalize-runtime.ap-southeast-2.amazonaws.com",
      "ca-central-1": "personalize-runtime.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "personalize-runtime"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_GetPersonalizedRanking_772924 = ref object of OpenApiRestCall_772588
proc url_GetPersonalizedRanking_772926(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPersonalizedRanking_772925(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773038 = header.getOrDefault("X-Amz-Date")
  valid_773038 = validateParameter(valid_773038, JString, required = false,
                                 default = nil)
  if valid_773038 != nil:
    section.add "X-Amz-Date", valid_773038
  var valid_773039 = header.getOrDefault("X-Amz-Security-Token")
  valid_773039 = validateParameter(valid_773039, JString, required = false,
                                 default = nil)
  if valid_773039 != nil:
    section.add "X-Amz-Security-Token", valid_773039
  var valid_773040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773040 = validateParameter(valid_773040, JString, required = false,
                                 default = nil)
  if valid_773040 != nil:
    section.add "X-Amz-Content-Sha256", valid_773040
  var valid_773041 = header.getOrDefault("X-Amz-Algorithm")
  valid_773041 = validateParameter(valid_773041, JString, required = false,
                                 default = nil)
  if valid_773041 != nil:
    section.add "X-Amz-Algorithm", valid_773041
  var valid_773042 = header.getOrDefault("X-Amz-Signature")
  valid_773042 = validateParameter(valid_773042, JString, required = false,
                                 default = nil)
  if valid_773042 != nil:
    section.add "X-Amz-Signature", valid_773042
  var valid_773043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773043 = validateParameter(valid_773043, JString, required = false,
                                 default = nil)
  if valid_773043 != nil:
    section.add "X-Amz-SignedHeaders", valid_773043
  var valid_773044 = header.getOrDefault("X-Amz-Credential")
  valid_773044 = validateParameter(valid_773044, JString, required = false,
                                 default = nil)
  if valid_773044 != nil:
    section.add "X-Amz-Credential", valid_773044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773068: Call_GetPersonalizedRanking_772924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
  ## 
  let valid = call_773068.validator(path, query, header, formData, body)
  let scheme = call_773068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773068.url(scheme.get, call_773068.host, call_773068.base,
                         call_773068.route, valid.getOrDefault("path"))
  result = hook(call_773068, url, valid)

proc call*(call_773139: Call_GetPersonalizedRanking_772924; body: JsonNode): Recallable =
  ## getPersonalizedRanking
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
  ##   body: JObject (required)
  var body_773140 = newJObject()
  if body != nil:
    body_773140 = body
  result = call_773139.call(nil, nil, nil, nil, body_773140)

var getPersonalizedRanking* = Call_GetPersonalizedRanking_772924(
    name: "getPersonalizedRanking", meth: HttpMethod.HttpPost,
    host: "personalize-runtime.amazonaws.com", route: "/personalize-ranking",
    validator: validate_GetPersonalizedRanking_772925, base: "/",
    url: url_GetPersonalizedRanking_772926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecommendations_773179 = ref object of OpenApiRestCall_772588
proc url_GetRecommendations_773181(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRecommendations_773180(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773182 = header.getOrDefault("X-Amz-Date")
  valid_773182 = validateParameter(valid_773182, JString, required = false,
                                 default = nil)
  if valid_773182 != nil:
    section.add "X-Amz-Date", valid_773182
  var valid_773183 = header.getOrDefault("X-Amz-Security-Token")
  valid_773183 = validateParameter(valid_773183, JString, required = false,
                                 default = nil)
  if valid_773183 != nil:
    section.add "X-Amz-Security-Token", valid_773183
  var valid_773184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773184 = validateParameter(valid_773184, JString, required = false,
                                 default = nil)
  if valid_773184 != nil:
    section.add "X-Amz-Content-Sha256", valid_773184
  var valid_773185 = header.getOrDefault("X-Amz-Algorithm")
  valid_773185 = validateParameter(valid_773185, JString, required = false,
                                 default = nil)
  if valid_773185 != nil:
    section.add "X-Amz-Algorithm", valid_773185
  var valid_773186 = header.getOrDefault("X-Amz-Signature")
  valid_773186 = validateParameter(valid_773186, JString, required = false,
                                 default = nil)
  if valid_773186 != nil:
    section.add "X-Amz-Signature", valid_773186
  var valid_773187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773187 = validateParameter(valid_773187, JString, required = false,
                                 default = nil)
  if valid_773187 != nil:
    section.add "X-Amz-SignedHeaders", valid_773187
  var valid_773188 = header.getOrDefault("X-Amz-Credential")
  valid_773188 = validateParameter(valid_773188, JString, required = false,
                                 default = nil)
  if valid_773188 != nil:
    section.add "X-Amz-Credential", valid_773188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773190: Call_GetRecommendations_773179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
  ## 
  let valid = call_773190.validator(path, query, header, formData, body)
  let scheme = call_773190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773190.url(scheme.get, call_773190.host, call_773190.base,
                         call_773190.route, valid.getOrDefault("path"))
  result = hook(call_773190, url, valid)

proc call*(call_773191: Call_GetRecommendations_773179; body: JsonNode): Recallable =
  ## getRecommendations
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
  ##   body: JObject (required)
  var body_773192 = newJObject()
  if body != nil:
    body_773192 = body
  result = call_773191.call(nil, nil, nil, nil, body_773192)

var getRecommendations* = Call_GetRecommendations_773179(
    name: "getRecommendations", meth: HttpMethod.HttpPost,
    host: "personalize-runtime.amazonaws.com", route: "/recommendations",
    validator: validate_GetRecommendations_773180, base: "/",
    url: url_GetRecommendations_773181, schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
