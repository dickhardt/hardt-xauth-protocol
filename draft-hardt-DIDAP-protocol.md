---
docname: draft-hardt-DIDAP-protocol-00
title: Delegated Identity and Authorization protocol
date: 2020-01-24

category: std
ipr: trust200902
area: Security
consensus: true

author:
    ins: D. Hardt
    organization: SignIn.Org
    role: editor
    name: Dick Hardt
    email: dick.hardt@gmail.com
    country: United States

normative:

  RFC3966:
  RFC5322:
  RFC5646:
  RFC6749:
  RFC6750:
  RFC7515:
  RFC7516:
  RFC7519:

  OIDC:
    title: OpenID Connect Core 1.0
    target: https://openiD.net/specs/openiD-connect-core-1_0.html
    date: November 8, 2014
    author:
      -
        ins: N. Sakimora
      -
        ins: J. Bradley
      -
        ins: M. Jones
      -
        ins: B. de Medeiros
      -
        ins: C. Mortimore

informative:

  RFC8252:
  RFC8628:

  browser based apps:
    title: OAuth 2.0 for Browser-Based Apps 
    target: https://tools.ietf.org/html/draft-ietf-oauth-browser-based-apps-04
    date: September 22, 2019
    author:
      -
        ins: A. Parecki
      -
        ins: D. Waite    
  
  RAR:
    title: OAuth 2.0 Rich Authorization Requests 
    target: https://tools.ietf.org/html/draft-lodderstedt-oauth-rar-03
    date: November 3, 2019
    author:
      -
        ins: T. Lodderstedt
      -
        ins: J. Richer
      -
        ins: B. Campbell

  W3C VC:
    title: Verifiable Credentials Data Model 1.0
    target: https://w3c.github.io/vc-data-model/
    date: November 26, 2019
    author:
      - 
        ins: M. Sporny
      - 
        ins: G. Noble
      - 
        ins: D. Chadwick

  QR Code:
    title: ISO/IEC 18004:2015 - Information technology - Automatic identification and data capture techniques - QR Code bar code symbology specification
    target: https://www.iso.org/standard/62021.html
    date: February 1, 2015

  TxAuth:
    title: Transactional Authorization
    target: https://tools.ietf.org/html/draft-richer-transactional-authz-04
    date: December 13, 2019
    author:
      -
        ins: J.Richer

--- abstract 

This protocol allows users and resource owners to delegate resource authorization and identity claims to a server. Client software can then obtain access to resources and/or identity claims by calling the delegated server. 

\[Editor: this is pretty terse and dense -- needs work!]

--- middle

# Introduction

This protocol supports the widely deployed use cases supported by OAuth 2.0, and OpenID Connect, as well as use cases those protocols don't support, but have been frequently requested. This protocol addresses many of the security issues in OAuth 2.0 by having parameters securely sent directly between parties, rather than via a browser redirection. 

The technology landscape has changed since OAuth 2.0 was initially drafted. More interactions happen on mobile devices than PCs. Modern browsers now directly support asymetric cryptographic functions. Standards have emerged for signing and encrypting tokens with rich payloads (JOSE) that are widely deployed.

Additional use cases are now being served with extensions to OAuth 2.0: OpenID Connect added support for authentication and releasing identity claims; {{RFC8252}} added support for native apps; {{RFC8628}} added support for smart devices; and support for {{browser based apps}} is being worked on.

This protocol takes advantage of the new capabilities, simplifies the architectural model, and provides support for all the widely deployed use cases. 

# Protocol

## Parties

- Delegated Server (DS) - provides the Client: authorization to API resources; and/or identity claims about the User. The DS may require explicit consent from the RO or User to provide these to the Client.

- Client - requests authorization to API resources, and/or identity claims about the User. There are two classes of Clients: those that have previously registered with the DS, and have a client id (Registered Clients), and those that have not (Unregistered Clients). A User may be interacting with the Client.

- User - the person who has delegated making identity claims about themselves to the DS, and is interacting with the Client.

- Resource Server (RS) - has API resources that require an access token from the DS for access.

- Resource Owner (RO) - owns the RS, and has delegated RS access token creation to the DS. The RO may be the same entity as the User, or may be a different entity that the DS interacts with independent of the Client.

## Sequence

1. **DS Discovery** The Client discovers the DS end point, keys, supported claims and authorizations, and other capabilities.  Some, or all of this information could be manually preconfigured, or dynamically obtained. DS discovery is out of scope of this document.
 
2. **Initiation Request** ({{InitiationRequest}}) The Client creates a request for authorization to API resources and/or identity claims about the User and sends it with an HTTP POST to the DS endpoint. 

3. **Initiation Response**  ({{InitiationResponse}}) The DS processes the request and determines if it needs to interact with the RO or User. If interaction is not required, the DS returns a completion response, otherwise the DS returns a completion handle. If the DS wants the Client to start the interaction, the DS sends interaction instructions to the Client. 

4. **Interaction** ({{Interaction}}) If the DS sent interaction instructions to the Client, the Client executes them. The DS then interacts with the User and/or RO to obtain authorization. 

5. **Completion Request** ({{CompletionRequest}}) If the Client received a completion handle and uri, it creates a completion token and does an HTTP GET of the completion URI, including the completion token in an HTTP header. The Client may make the completion request while waiting for the interaction to complete. 

6. **Completion Response** ({{CompletionResponse}}) When any required interaction has been completed, the DS responds to the Client with authorized RS access tokens and User identity claims. The DS may provide refresh handles and uris for each access token if they are authorized. If proof of possession is required for a accessing a resource, the DS will provide certificate parameters for the Client to include in the signed request. 

7. **Resource Request** ({{Resource}}) The Client uses an access token with the RS, or creates a JOSE access token with the access handle if proof of possession is required for access. 

8. **Access Token Refresh** ({{Refresh}}) If the Client received a refresh handle and uri, it creates a refresh token and does an HTTP GET of the refresh URI, including the refresh token in an HTTP header.

# Discovery

The Client obtains the following metadata about the DS prior to initiating a request:

**Endpoint** - the endpoint of the DS.

**ds** - the unique string identifier for the DS. Used in "ds" parameters of JOSE tokens.

**Algorithms** - the asymetric cryptographic algorithms supported by the DS. 

**Authorizations** - the authorizations the Client may ask for, if any.

**Identity Claims** - the identity claims the Client may request, if any, and what public keys the claims will be signed with.

**Initiation Request Encryption** - if the DS requires the the initiation request to be encrypted, and which public key to use.

**Completion Response Signing** - if the DS will sign the completion response, and the matching public key to verify the signature.

# Initiation

The Client initiates a request for authorizations and/or identity claims with an initiation request.

## Initiation Request {#InitiationRequest}

The Client creates a payload, signs it using JWS {{RFC7515}}, and sends the signed payload to the DS end point using HTTP POST, with a content-type of application/jose. The payload is a JSON document and MUST include a client object. The payload MAY include a user object. The payload MUST include an authorizations or claims object, or both. 

Following is a non-normative example of an initiation request JWS header and payload for an Unregistered Client implemented as a single page app (SPA). The Client wants to interact with the User with a popup and is requesting identity claims about the User and read access to the User's contacts:

    "header": {
        "alg": "ES256",
        "typ": "JOSE",
        "jwk": {
            "kty":"EC",
            "crv":"P-256",
            "x":"Kgl5DJSgLyV-G32osmLhFKxJ97FoMW0dZVEqDG-Cwo4",
            "y":"GsL4mOM4x2e6iON8BHvRDQ6AgXAPnw0m0SfdlREV7i4"
        }
    }

    "payload": { 
        "ds"    :"https://ds.example",
        "iat"   :"1579046092",
        "nonce" :"f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "client": {
            "display": {
                "name"  : "SPA Display Name",
                "uri"   : "https://spa.example/about"
            },
            "interaction": {
                "type": "popup"
            }
        },
        "authorizations": {
            "oauth_scope": "read_contacts"
        },
        "claims": {
            "oidc": {
                "id_token" : {
                    "email"          : { "essential" : true },
                    "email_verified" : { "essential" : true }
                },
                "userinfo" : {
                    "name"           : { "essential" : true },
                    "picture"        : null
                }
            }
        }
    }


Following is a non-normative example of an initiation request JWS header and payload for a Registered Client implemented as a backend service with a simple web interface, that has previously authenticated the User, and is requesting additional authorization:

    "header": {
        "alg": "ES256",
        "typ": "JOSE",
        "kid": "1"
    }

    "payload": { 
        "ds":"https://ds.example",
        "iat":"1579046092",
        "nonce":"0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "client": {
            "id": "di3872h34dkJW",
            "interaction": {
                "type": "redirect",
                "uri": "https://web.example/return"
            }
        },
        "user": {
            "identifiers": {
                "oidc": {
                    "iss": "https://ds.example",
                    "sub": "123456789"
                }
            }
        },
        "authorizations": {
            "oauth_scope": "read_calendar write_calendar"
        }
    }

### Payload Attributes

**ds** - the  unique string identifier for the DS

**iat** - the time of the request per [RFC7519] section 4.1.6.

**nonce** - a unique identifier for this request. The completion response MUST contain a matching nonce value.


### "client" Object
The client object MUST contain the client_id attribute for Registered Clients, or the display object for Unregistered Clients. If the Client can interact with the User, then an interaction object is included.

**client_id** - the identifier the DS has for the Client.

**display** - the display object contains the following attributes:

+ **name** - a string that represents the Client
+ **uri** - a URI representing the Client 

The name and uri will be displayed by the DS when prompting for authorization.

**interaction** - the interaction object contains the type of interaction the Client will provide the User. Other attributes are dependent on the interaction type value.

+ **type** - contains one of the following values. Types are listed from highest to lowest fidelity. The interaction URI is the value returned by the DS in the initiation response interaction object {{interactionObject}}, if a User interaction is required by the DS.

    + **popup** - the Client will load the interaction URI in a modal popup window. The DS will close the window when the interaction is complete.
    + **redirect** - the Client will redirect the user agent to the interaction URI provided by the DS. The DS will redirect to the redirect_uri when the interaction is completed,
    + **qrcode** - the Client will convert the interaction URI to a QR Code per {{QR Code}} and display it to the User, along with a text message. The User will scan the QR Code and/or follow the message instructions.

+ **redirect_uri** - this attribute is included if the type is redirect. It is the URI that the Client requests the DS to redirect the User to after the DS has completed interacting with the User. If the Client manages state in URLs, then the redirect_uri should contain that state.

+ **ui_locales** - End-User's preferred languages and scripts for the user interface, represented as a space-separated list of {{RFC5646}} language tag values, ordered by preference.

\[Editor: do we need max pixels or max chars for qrcode interaction? Either passed to DS, or max specified values here?]

\[Editor: other possible interaction models could be a `webview`, where the Client can display a web page, or a `message`, where the client can only display a text message]

\[Editor: we may need to include interaction types for iOS and Android as the mobile OS APIs evolve.]

\[Editor: does the Client include parameters if it wants the completion response signed and/or encrypted?]

### "user" Object
The user object is optional. 

**identifiers** - the identifiers object contains one or more of the following identifiers for the User:

+ **phone_number** - contains a phone number per Section 5 of {{RFC3966}}.

+ **email** - contains an email address per {{RFC5322}}.

+ **oidc** - is an object containing both the `iss` and `sub` attributes from an OpenID Connect ID Token per {{OIDC}} Section 2.

The user and identifiers objects are included to improve the user experience by the DS. The DS MUST authenticate the User independent of these values.

\[Editor: include full ID Token? multiple identifiers of the same type?]

### "authorizations" Object

The optional authorizations object contains a dictionary of resource objects the Client is requesting authorization to access. The authorizations object may contain one or more of:

+ **oauth_scope** - a string containing the OAuth 2.0 scope per {{RFC6749}} section 3.3.

+ **oauth_rich** - an authorization_details object per {{RAR}}. The oauth_rich request is independent of the oauth_scope request.

+ **oauth_rich_list** - an array of authorization_details objects per {{RAR}}

The authorizations object MUST contain only one of oauth_rich and oauth_rich_list. 

### "claims" Object
The optional claims object contains one or more identity claims being requested. The claims may contain:

+ **oidc** - an object that contains one or both of the following objects:

    - **userinfo** - claims that will be returned if this is the first interaction with User at the Registered Client 

    - **id_token** - claims that will be included in the returned ID Token

The contents of the userinfo and id_token objects are defined by {{OIDC}} Section 5. The completion response is specified in {{CompletionResponse}}. 

* vc - \[Editor: define how W3C Verifiable Credentials {{W3C VC}} can be requested ]

### Payload Signing

The initiation request payload is signed per JWS {{RFC7515}} with the private key matching the public key included, or referenced by the jwk object or kid attribute of the JWS header object. The resulting JWS {{RFC7515}} compact serialization token is the body of the HTTP POST to the DS. An Unregistered Client MUST generate an asymetric key pair and include the public key in the JWS header's jwk object.

### Payload Encryption

The DS may require the initiation request payload to be encrypted. If so, the JWS signed token is encrypted per JWE {{RFC7516}} using the public key and algorithm provided by the DS.

## Initiation Response {#InitiationResponse}

If no interaction is required the DS will return a completion response per {{CompletionResponse}}. If the DS wants the Client to start the interaction, the DS will return an HTTP 200 response with a content-type of application/json will include an interaction object. If an interaction is required, wether started by the Client, or the DS, there MUST be a completion object in the response.

A non-normative example of an initiation response follows:

    {
        "interaction": {
            "type"   : "popup",
            "uri"    : "https://ds.example/endpoint/ey5gs32..."
        },
        "completion": {
            "handle" : "eyJhb958.example.completion.handle.9yf3szM",
            "uri"    : "https://ds.example/completion/ey7snHGs"
        }
    }

\[Editor: do we want to allow the DS to optionally return a period of time the Client must wait before making a completion request? Prefer to keep it simple for client and let the client call when it is ready.]

### "interaction" Object {#interactionObject}

uri to redirect to, or popup, or show in QR, or message to be displayed


If the DS wants the Client to start the interaction, the DS MUST select one of the interaction mechanisms provided by the Client in the initiation request, and include the matching attribute in the interaction object: 

+ **type** - this MUST match the type provided by the Client in the initiation request client.interaction object.

+ **uri** - the URI to interact with the User per the type. This may be a temporary short URL if the type is qrcode so that it is easy to scan.

+ **message** - a text string to display to the User if type is qrcode.

### "completion" Object

The completion object has the following attributes:

+ **handle** - the completion handle.

+ **uri** - the completion URI.

### Error Responses

TBD

# Interaction {#Interaction}
If the DS wants the Client to initiate the interaction with the User, then the DS will return an interaction object {{interactionObject}} so that the Client can can hand off interactions with the User to the DS. The Client will initiate the interaction with the User in one of the following ways: 

## popup
The Client will create a new popup child browser window containing the value of the uri attribute of the interaction object. 
\[Editor: more details on how to do this]

The DS will close the window when the interactions with the User are complete. \[Editor: confirm DS can do this still on all browsers, or does Client need to close] 

The DS MAY respond to the completion request {{CompletionRequest}} before the popup window has been closed.

## redirect
The Client will redirect the User to the value of the uri attribute of the interaction object. When the DS interactions with the User are complete, the DS will redirect the User to the redirect_uri the Client provided in the initiation request.

If the Client made a completion request when starting the interaction, the DS MAY respond to the completion request {{CompletionRequest}} before the User has been redirected back to the Client. 

## qrcode
The Client will create a {{QR Code}} of the uri attribute of the interaction object and display the resulting graphic and the message attribute of the interaction object as a text string.

# Completion 

If the Client received a completion handle and uri from the DS in the initiation response, it creates a completion token and makes a GET request to the completion URI, passing the Client constructed completion token in the HTTP Authorization header with the JOSE parameter. The DS will then response with the completion response, which are the results of the initiation request unless there was an error or the connection timed out with an HTTP 408 response.

## Creating a Completion Token {#CompletionToken}

The completion token is a JWS, and the Client uses the same private key and header used to create the initiation request {{InitiationRequest}}. 
The payload of the completion token contains:

**ds** - the unique string identifier for the DS.

**iat** - the time the completion token was created.

**jti** - a unique identifier for the completion token per {{RFC7519}} section 4.1.7.

**handle** the completion handle the DS provided the Client in the initiation response {{InitiationResponse}}.

A non-normative example of the header and payload of a completion token follows:


    "header": {
        "alg": "ES256",
        "typ": "JOSE",
        "jwk": {
            "kty":"EC",
            "crv":"P-256",
            "x":"Kgl5DJSgLyV-G32osmLhFKxJ97FoMW0dZVEqDG-Cwo4",
            "y":"GsL4mOM4x2e6iON8BHvRDQ6AgXAPnw0m0SfdlREV7i4"
        }
    }

    "payload": {
        "ds":  "https://ds.example",
        "iat": "1579046092",
        "jti": "f6d72254-4f23-417f-b55e-14ad323b1dc1",
        "handle": "eyJhb958.example.completion.handle.9yf3szM"
    }



## Completion Request {#CompletionRequest}

The Client then makes an HTTP GET call to the completion uri, setting the HTTP Authorization header to have the JOSE parameter, followed by the completion token.

A non-normative completion request example:

    GET /completion/ey7snHGs HTTP/1.3
    Host: ds.example
    Authorization: JOSE eyJhbGciOiJFU.example.completion.token.haDwskpFDBW

## Completion Response {#CompletionResponse}

The DS verifies the completion token, and then provides a response according to what the User and/or RO have authorized if required. If no signature or encryption was required, the DS will respond with a JSON document with content-type set to application/JSON.

Example non-normative completion response JSON documents for the 2 examples in {{InitiationRequest}}:

    { 
        "iat":"15790460234",
        "nonce":"f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "authorizations": {
            "oauth_scope": {
                "scope"         : "read_contacts",
                "expires_in"    : "3600",
                "type"          : "bearer",
                "token"         : "eyJJ2D6.example.access.token.mZf9p"
            }
        },
        "claims": {
            "oidc": {
                "id_token"      : "eyJhbUzI1N.example.id.token.YRw5DFdbW",
                "userinfo" : {
                    "name"      : "John Doe",
                    "picture"   : "https://photos.example/p/eyJzdkiO"
                }
            }
        }
    }

    {
        "iat":"15790460234",
        "nonce":"0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "authorizations": {
            "oauth_scope": {
                "scope"         : "read_calendar write_calendar",
                "expires_in"    : "3600",
                "type"          : "jose",
                "access": {
                    "handle"    : "ey.example.access.handle.9yf3szM",
                    "jwk": {
                        "x5u"   : "https://ds.example/jwk/VBUEOIQA82" 
                    }       
                },
                "refresh": {
                    "handle"    : "ey.example.refresh.handle.Jl4FzM",
                    "uri"       : "https://ds.example/refresh/eyj34"
                }
            }
        }
    }


Details of the JSON document: 

**iat** - the time the response was made.

**nonce** - the nonce that was included in the initiation request {{InitiationRequest}}.


### "authorizations" Object

There is an authorizations object in the completion response if there was an authorizations object in the initiation request. 

+ **oauth_scope** - if there was an oauth_scope object in the initiation request, this object will be returned if some or all of the scopes were authorized

    + **scope** - the scopes the Client was granted authorization for. This will be all, or a subset, of what was requested.

    + **type** - the type of access: "bearer" or "jose". See {{TokenTypes}} for details.

    + **token** - an access token for accessing the resource(s). Included if the type of access is "bearer".

    + **expires_in** - an optional value specifying how many seconds until the access token or handle expire. 

    + **refresh** - an optional object containing parameters required to refresh an access token or handle.

        + **handle** - an refresh handle used to create the refresh token. See {{Refresh}}

        + **uri** - the refresh uri the Client will use to refresh.

    + **access** - an object containing the parameters needed to access resources requiring proof of possession. Included if the type of access is "jose".
        
        + **handle** - the access handle to use to create the JOSE access token.

        + **jwk** - the jwk value to use when signing the JOSE access token.


+ **oauth_rich** - if there was an oauth_rich object in the initiation request, this object will be returned if some or all of the authorization requests were granted. The contents are the same as the oauth_scope object, except the "scope" parameter is replaced with the details object:

    + **details** - the authorization details that were granted.

+ **oauth_rich_list** - if there was an oauth_rich_list object in the initiation request, this object will contain a list matching each item in the list of the initiation request. Each response will be the same as the oauth_rich object. 

### "claims" Object

There is a claims object in the completion response if there was a claims object in the initiation request. 

+ **oidc**

    - **id_token** - an OpenID Connect ID Token containing the claims the user consented to be released.

    - **userinfo** - if the Client has not previously received an id_token from the DS for the User, then this object contains a dictionary of the identity claims the user consented to be released, if any. If the Client has previously received an ID Token from the DS for the User and an id_token was in this request, the userinfo object only contains the attribute "redundant" set to the value true. If the Client would like to request additional claims about the User, the Client can make a request containing the userinfo object, and not containing the id_token object.    

\[Editor: does this work? It allows depreciation of the UserInfo endpoint, and the associated access token. It requires state to be managed by the DS, but implementations already manage state.]

+ **vc**

    The verified claims the user consented to be released. \[Editor: details TBD]


### Access Types {#TokenTypes}

There are two types of access:

+ **bearer** - the DS provides a bearer access token that the Client can use to access resources per {{Bearer}}.

+ **jose** - the DS provides an access handle that the Client uses to create a JWS to access resources per {{POP}}.

The string values of the access types are case insensitive. 

### Response Signing

The DS MAY sign the response with a JWS per {{RFC7515}} and the private key matching the public key the DS defined as its completion response signing key.

### Response Encryption

The DS MAY encrypt the response using the public key provided by the Client, using JWE per {{RFC7516}}.

### Error Responses

+ **408** Request Timeout. The DS may return a 408 code if it wants to terminate the completion request. The Client SHOULD generate a fresh completion token and make a new completion request.

# Resource Request {#Resource}

Once the Client has an access token or handle, the Client can access protected resources.

## Bearer Token Access {#Bearer}

If the token type in the completion response was "bearer", then the Client can access the resource per Section 2.1 of {{RFC6750}}

A non-normative example follows:

    Authorization: bearer eyJJ2D6.example.access.token.mZf9pTSpA

## Proof of Possession Access {#POP}

If the token type in the completion response was "jose", then the Client creates a JOSE access token for each API call, signing it with its private key, but setting the jwk object in the JWS header to be the jwk value returned in the completion response {{CompletionResponse}}. This allows the DS to provide the resource with a certificate binding the Client's private key to the authorization granted. A non-normative example of the header and payload of the JWS follows:

    "header": {
        "alg": "ES256",
        "typ": "JOSE",
        "jwk": {
            "x5u": "https://ds.example/jwk/VBUEOIQA82" 
        }
    }

    "payload": {
        "iat"    : "1579046092",
        "jti"    : "f6d72254-4f23-417f-b55e-14ad323b1dc1",
        "handle" : "ey.example.access.handle.9yf3szM"
    }

The payload contains the following attributes:

**iat** - the time the JOSE access token was created.

**jti** a unique identifier for the JOSE access token per {{RFC7519}} section 4.1.7.

**handle** the access handle the DS provided the Client in the completion response {{CompletionResponse}}.

The Client then sets the HTTP Authorization header in the resource request to have the "jose" parameter, followed by the JOSE access token. A non-normative example follows:

    GET /calendar HTTP/1.3
    Host: calendar.example
    Authorization: JOSE eyJhbG.example.token.kwwQb958

# Access Token or Handle Refresh {#Refresh}

If the Client received a refresh handle and uri from the DS in the initiation response, and it wants a fresh access token or handle, it creates a refresh token using the refresh handle in the same manner that the Client creates a completion token {{CompletionToken}}.


The Client then makes an HTTP GET call to the refresh uri, setting the HTTP Authorization header to have the JOSE parameter, followed by the refresh token.

The DS will then respond with a refresh response, that is of the same format of the object that contained the refresh handle and uri in the completion response {{CompletionResponse}}.

A non-normative example of a refresh token header and payload:

    "header": {
        "alg": "ES256",
        "typ": "JOSE",
        "kid": "1"
    }

    "payload": {
        "ds"        : "https://ds.example",
        "iat"       : "1579046092",
        "jti"       : "332c2348-f9ed-4278-98eb-7e39b20347ee",
        "handle"    : "eyJhb.example.refresh.handle.9yf3szM",
    }

A non-normative example refresh request:

    GET /refresh/eyJhb958 HTTP/1.3
    Host: ds.example
    Authorization: JOSE eyJhbG.example.refresh.token.kwwQb958

A non-normative example access handle refresh response:

    {
        "scope"             : "read_calendar write_calendar",
        "expires_in"        : "3600",
        "type"              : "jose",
        "access": {
            "handle"        : "ey.example.access.handle.9yf3iWszM",
            "jwk": {
                "x5u"       : "https://ds.example/jwk/VBUEOIQA82" 
            }       
        },
        "refresh": {
            "handle"        : "ey.example.refresh.handle.4SkjIi",
            "uri"           : "https://ds.example/refresh/eyJl4FzM"
        }
    }

# Client Authentication {#ClientAuthN}

All calls from the Client to the DS are authenticated with the same private key and JWS header. This Client authenticates by signing the initiation request, the completion token, and the refresh token.

When accessing resources that require proof of possession, the Client uses the same private key, but the DS supplied jwk object. The DS supplied jwk object is a certificate or certificate chain with a public key the resource trusts, so that the resource can verify the authorized client, allowing Registered and Unregistered Clients to access proof of possession resources the same way. 

Each instance of a Registered Client MAY have its own private key and then include a certificate or certificate chain, or reference to either, in the JWS header jwk object that binds its public key to the public key the DS has for the Registered Client.

# DS Initiated Authentication and Authorization

\[Editor: this is a straw man on how to support DS Initiated authentication, JIT provisioning, and authorization]

There are a number of user experiences where the User starts at the DS, and then is redirected to the Client, which MUST be a Registered Client.

1. The User is at the DS and wants to use the Client.

1. The DS creates a completion handle and uri representing the User, any identity claims the User has consented to be shared with the Client, any authorizations the User or RO have consented to be shared with the Client, and the Client. 

1. The DS redirects the User to a URL the Client has configured to accept DS initiated authentication, passing the completion handle and uri as query parameters "handle" and "uri" respectively. 

1. The Client then creates a completion token and makes a completion request per {{CompletionRequest}}, and the DS responds per {{CompletionResponse}}.

The Client now has the identity claims for the User, and any authorizations. Client can perform just in time provisioning if it is a new User.

# Extensibility

This standard can be extended in a number of areas:

## Client Authentication Mechanisms

An extension could define other mechanisms for the Client to authenticate. For example COSE for constrained environments using COAP, MTLS, HTTP signing if and when a standard is adopted and deployed.

## Initiation Request

An additional top level object could be added to the initiation request payload if the DS can handle delegations other than authorizations or claims.

### "client" Object

Other information about the Client that the DS would require related to an extension.

### "user" Object

Other information about the Client that the DS would require related to an extension.

### "authorizations" Object

Additional types of authorizations in addition to OAuth 2.0 scopes and RAR.

### "claims" Object

Additional types of identity claims in addition to OpenID Connect claims and Verified Credentials.

## Interaction

Additional mechanisms for the Client to start an interaction with the User.

## Access Token Types

Additional mechanisms for the Client to present authorization to a resource.

# Rational



1. **Why is there only one mechanism for the Client to authenticate with the DS? Why not support other mechanisms?**

    Having choices requires implementers to understand which choice is preferable for them. Having one common mechanism for the Client to authenticate simplifies most implementations. Extensions can specify other mechanisms that are preferable in certain environments. 

1. **Why is the Client authentication JWS rather than MTLS?**

    MTLS cannot be used by an Unregistered Client. MTLS requires access below the application layer, that is often not available on some platforms. JWS is done at the application layer. Many DS deployments will be an application behind a proxy performing TLS, and there are risks in the proxy passing on the results of MTLS.

1. **Why is the Client authentication JWS rather than HTTP signing?**

    There is currently no widely deployed HTTP signing standard. Additionally, HTTP signing requires passing all the relevant parts of the HTTP request to downstream services in a DS that may need to independently verify the Client identity.

1. **What are the advantages of using JWS for the Client to authenticate to the DS and a resource?**
    
    Both Registered Clients, and Unregistered Clients can have a private key, eliminating the public Client issues in OAuth 2.0, as an Unregistered Client can create an ephemeral key pair. Using asymetric cryptography also allows each instance of a Registered Client to have its own private key if it can obtain a certificate binding its public key to the public key the DS has for the Client. Signed tokens can be passed to downstream components in a DS or resource to enable independent verification of the Client.

1. **Why does the DS not return parameters to the Client in the redirect url?**

    Passing parameters via a browser redirection is the source of many of the security risks in OAuth 2.0. It also presents a challenge for smart devices. In this protocol, the redirection from the Client to the DS is enable the DS to interact with the User, and the redirection back to the Client is to hand back the interaction to the Client. Unlike OAuth 2.0, the identity of the Client is independent of the URI the DS redirects to.

1. **Why is it a Delegated Server, not an Authorization Server?**

    This broadens the DS to serve both as an OAuth AS, and an OpenID Connect OpenID Provider, both are servers that have had functionality delegated to them. It also provides extensibility for other delegations. Additionally, it differentiates a an implementation of this protocol when referencing the server.

1. **Why not use bearer tokens for completion and refresh?**

    By requiring the Client to prove possession of it's private key, the completion and refresh tokens are not as sensitive, and the security of the protocol is enhanced as leakage of the tokens does not enable access to functionality.

1. **Why is there not a UserInfo endpoint as there is in OpenID Connect?**

    In OpenID Connect, the Client does not know if it has seen the User previously until it receives the ID Token. By passing an access token for the UserInfo endpoint, the Client can minimize the amount of information returned with the ID Token, and only call the UserInfo endpoint for new Users. 
    
    This simplifies this common flow. If the User is new to the Client, the userinfo requests are returned, otherwise they are not. If the Client would like to acquire additional claims about the User after they have authenticated to the Client, the Client can make an additional request that only contains the userinfo object. 

1. **Why do is there still a Client ID? Could we not use a fingerprint of the public key to identify the Client?**

    When supporting Clients, it is useful to be able to refer to a permanent identifier for a Registered Client. Using a fingerprint or public key to identify the Client has the Client identifier change every time the key is rotated. A DS logging Client activity will have a single identifier to track a Client. Having a Client ID eases a transition to this protocol from OAuth 2.0.

# Acknowledgments

This draft derives many of its concepts from Justin Richer's Transactional Authorization draft {{TxAuth}}. Thanks to Justin for his strong critique of this draft.


# IANA Considerations

\[ JOSE parameter for Authorization HTTP header ]

TBC

# Security Considerations

TBC

--- back

# Document History

## draft-hardt-DIDAP-protocol-00

- Initial version

# Comparison with OAuth 2.0 and OpenID Connect

## Differences

The major differences between this protocol and OAuth 2.0 and OpenID Connect are:

+ The Client uses a private key to authenticate in this protocol instead of the client secret in OAuth 2.0 and OpenID Connect.

+ The Client initiates the protocol by making a signed request to the DS instead of redirecting the User to the AS.

+ The Client does not receive any parameters from a redirection of the User back from the AS.

+ Refreshing an access token requires creating a refresh token from a refresh handle, rather than an authenticated call with a refresh token.

+ The Client can request identity claims to be returned independent of the ID Token. There is no UserInfo endpoint to query claims as there is in OpenID Connect.

## Reused 

+ This protocol reuses the OAuth 2.0 scopes, client ids, access tokens, and API authorization of OAuth 2.0. 

+ This protocol reuses the client ids, claims and ID Token of OpenID Connect.
