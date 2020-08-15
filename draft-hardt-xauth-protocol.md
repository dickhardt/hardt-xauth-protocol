---
docname: draft-hardt-xauth-protocol-14
title: The Grant Negotiation and Authorization Protocol
date: 2020-08-12
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

  RFC2119:
  RFC3966:
  RFC5322:
  RFC4949:
  RFC5646:
  RFC6749:
  RFC6750:
  RFC7519:
  RFC8259:

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

  OIDC4IA:
    title: OpenID Connect for Identity Assurance 1.0
    target: https://openid.net/specs/openid-connect-4-identity-assurance-1_0.html
    date: October 15, 2019
    author:
      -
        ins: T. Lodderstedt
      -
        ins: D. Fett
  
  RAR:
    title: OAuth 2.0 Rich Authorization Requests 
    target: https://tools.ietf.org/html/draft-ietf-oauth-rar-00
    date: January 21, 2020
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

  JOSE Authentication:
    title: JOSE Authentication 
    target: https://tools.ietf.org/html/draft-hardt-gnap-jose
    date: June 6, 2020
    author:
      -
        ins: D. Hardt

  GNAP Advanced:
    title: The Grant Negotiation and Authorization Protocol - Advanced Features 
    target: https://tools.ietf.org/html/draft-hardt-gnap-advanced
    date: June 7, 2020
    author:
      -
        ins: D. Hardt

informative:

  RFC7049:
  RFC8152:
  RFC8323:

  browser based apps:
    title: OAuth 2.0 for Browser-Based Apps 
    target: https://tools.ietf.org/html/draft-ietf-oauth-browser-based-apps-04
    date: September 22, 2019
    author:
      -
        ins: A. Parecki
      -
        ins: D. Waite    


  QR Code:
    title: ISO/IEC 18004:2015 - Information technology - Automatic identification and data capture techniques - QR Code bar code symbology specification
    target: https://www.iso.org/standard/62021.html
    date: February 1, 2015

  TxAuth:
    title: Transactional AuthN
    target: https://tools.ietf.org/html/draft-richer-transactional-authz-04
    date: December 13, 2019
    author:
      -
        ins: J. Richer
        
  IANA JWT:
    title: JSON Web Token Claims
    target: https://www.iana.org/assignments/jwt/jwt.xhtml
    date: January 23, 2015

--- abstract 

Client software often desires resources or identity claims that are independent of the client. This protocol allows a user and/or resource owner to delegate resource authorization and/or release of identity claims to a server. Client software can then request access to resources and/or identity claims by calling the server. The server acquires consent and authorization from the user and/or resource owner if required, and then returns to the client software the authorization and identity claims that were approved. This protocol may be extended on many dimensions.

--- middle

# Introduction


**EDITOR NOTE**

*This document captures a number of concepts that may be adopted by the proposed GNAP working group. Please refer to this document as:* 

**XAuth**

*The use of GNAP in this document is not intended to be a declaration of it being endorsed by the GNAP working group.* 


This document describes the core Grant Negotiation and Authorization Protocol (GNAP). The protocol supports the widely deployed use cases supported by OAuth 2.0 {{RFC6749}} & {{RFC6750}}, OpenID Connect {{OIDC}} - an extension of OAuth 2.0, as well as other extensions. Related documents include: GNAP - Advanced Features {{GNAP Advanced}} and JOSE Authentication {{JOSE Authentication}} that describes the JOSE mechanisms for client authentication. 

The technology landscape has changed since OAuth 2.0 was initially drafted. More interactions happen on mobile devices than PCs. Modern browsers now directly support asymetric cryptographic functions. Standards have emerged for signing and encrypting tokens with rich payloads (JOSE) that are widely deployed.

GNAP simplifies the overall architectural model, takes advantage of today's technology landscape, provides support for all the widely deployed use cases, offers numerous extension points, and addresses many of the security issues in OAuth 2.0 by passing parameters securely between parties rather than via a browser redirection. 

While GNAP is not backwards compatible with OAuth 2.0, it strives to minimize the migration effort.

The suggested pronunciation of GNAP is "guh-nap". 

## The Grant

The Grant is at the center of the protocol between a client and a server. A Grant Client requests a Grant from a Grant Server. The Grant Client and Grant Server negotiate the Grant. The Grant Server acquires authorization to grant the Grant to the Grant Client. The Grant Server then returns the Grant to the Grant Client. 

The Grant Request may contain information about the User, the Grant Client, the interaction modes supported by the Grant Client, the requested identity claims, and the requested resource access. Extensions may define additional information to be included in the Grant Request.

## Protocol Roles {#ProtocolRoles}

There are three roles in GNAP: the Grant Client (GC), the Grant Server (GS), and the Resource Server (RS). Below is how the roles interact:

        +--------+                               +------------+
        | Grant  | - - - - - - -(1)- - - - - - ->|  Resource  |
        | Client |                               |   Server   |
        |  (GC)  |       +---------------+       |    (RS)    |
        |        |--(2)->|     Grant     |       |            |
        |        |<-(3)->|     Server    |- (6) -|            |
        |        |<-(4)--|      (GS)     |       |            |
        |        |       +---------------+       |            |
        |        |                               |            |
        |        |--------------(5)------------->|            |
        +--------+                               +------------+

(1) The GC may query the RS to determine what the RS requires from a GS for resource access. This step is not in scope for this document.

(2) The GC makes a Grant request to the GS (Create Grant {{CreateGrant}}). How the GC authenticates to the GS is not in scope for this document. One mechanism is {{JOSE Authentication}}. 

(3) The GC and GS may negotiate the Grant. 

(4) The GS returns a Grant to the GC (Grant Response {{GrantResponse}}).

(5) The GC accesses resources at the RS (RS Access {{RSAccess}}). 

(6) The RS evaluates access granted by the GS to determine access granted to the GC. This step is not in scope for this document. 

## Human Interactions

The Grant Client may be interacting with a human end-user (User), and the Grant Client may need to get authorization to release the Grant from the User, or from the owner of the resources at the Resource Server, the Resource Owner (RO)

Below is when the human interactions may occur in the protocol:

        +--------+                               +------------+
        |  User  |                               |  Resource  |
        |        |                               | Owner (RO) |
        +--------+                               +------------+
            +     +                             +      
            +      +                           +      
           (A)     (B)                       (C)       
            +        +                       +        
            +         +                     +         
        +--------+     +                   +     +------------+
        | Grant  | - - -+- - - -(1)- - - -+- - ->|  Resource  |
        | Client |       +               +       |   Server   |
        |  (GC)  |       +---------------+       |    (RS)    |
        |        |--(2)->|     Grant     |       |            |
        |        |<-(3)->|     Server    |- (6) -|            |
        |        |<-(4)--|      (GS)     |       |            |
        |        |       +---------------+       |            |
        |        |                               |            |
        |        |--------------(5)------------->|            |
        +--------+                               +------------+

    Legend
    + + + indicates an interaction with a human
    ----- indicates an interaction between protocol roles


Steps (1) - (6) are the same as {{ProtocolRoles}}. The addition of the human interactions (A) - (C) are **bolded** below.

**(A) The User is interacting with a GC, and the GC needs resource access and/or identity claims (a Grant)**

(1) The GC may query the RS to determine what the RS requires from a GS for resource access

(2) The GC makes a Grant request to the GS

(3) The GC and GS may negotiate the Grant

**(B) The GS may interact with the User for grant authorization**

**(C) The GS may interact with the RO for grant authorization**

(4) The GS returns a Grant to the GC

(5) The GC accesses resources at the RS

(6) The RS evaluates access granted by the GS to determine access granted to the GC


Alternatively, the Resource Owner could be a legal entity that has a software component that the Grant Server interacts with for Grant authorization. This interaction is not in scope of this document.


## Trust Model

In addition to the User and the Resource Owner, there are three other entities that are part of the trust model:

- **Client Owner** (CO) - the legal entity that owns the Grant Client.
- **Grant Server Owner** (GSO) - the legal entity that owns the Grant Server.
- **Claims Issuer** (Issuer) - a legal entity that issues identity claims about the User. The Grant Server Owner may be an Issuer, and the Resource Owner may be an Issuer.

These three entities do not interact in the protocol, but are trusted by the User and the Resource Owner:


      +------------+           +--------------+----------+
      |    User    | >> (A) >> | Grant Server |          |
      |            |           | Owner (GSO)  |          | 
      +------------+         > +--------------+          |
            V              /          ^       |  Claims  |
           (B)          (C)          (E)      |  Issuer  |
            V          /              ^       | (Issuer) |
      +------------+ >         +--------------+          |
      |  Client    |           |   Resource   |          |
      | Owner (CO) | >> (D) >> |  Owner (RO)  |          |
      +------------+           +--------------+----------+

(A) User trusts the GSO to acquire authorization before making a grant to the CO

(B) User trusts the CO to act in the User's best interest with the Grant the GSO grants to the CO

(C) CO trusts claims issued by the GSO 

(D) CO trusts claims issued by the RO 

(E) RO trusts the GSO to manage access to the RO resources


## Terminology

**Roles**

- **Grant Client** (GC) 
    - may want access to resources at a Resource Server
    - may be interacting with a User and want identity claims about the User
    - requests the Grant Service to grant resource access and identity claims

- **Grant Server** (GS) 
    - accepts Grant requests from the GC for resource access and identity claims
    - negotiates the interaction mode with the GC if interaction is required with the User
    - acquires authorization from the User before granting identity claims to the GC
    - acquires authorization from the RO before granting resource access to the GC
    - grants resource access and identity claims to the GC

- **Resource Server** (RS) 
    - has resources that the GC may want to access
    - expresses what the GC must obtain from the GS for access through documentation or an API. This is not in scope for this document
    - verifies the GS granted access to the GC, when the GS makes resource access requests

**Humans** 

- **User** 
    - the person interacting with the Grant Client.  
    - has delegated access to identity claims about themselves to the Grant Server.
    - may authenticate at the GS.

- **Resource Owner** (RO) 
    - the legal entity that owns resources at the Resource Server (RS).
    - has delegated resource access management to the GS. 
    - may be the User, or may be a different entity that the GS interacts with independently.


**Reused Terms**

- **access token** - an access token as defined in {{RFC6749}} Section 1.4. An GC uses an access token for resource access at a RS.

- **Claim** - a Claim as defined in {{OIDC}} Section 5. Claims are issued by a Claims Issuer. 

- **Client ID** - a GS unique identifier for a Registered Client as defined in {{RFC6749}} Section 2.2.

- **ID Token** - an ID Token as defined in {{OIDC}} Section 2. ID Tokens are issued by the GS. The GC uses an ID Token to authenticate the User.

- **NumericDate** - a NumericDate as defined in {{RFC7519}} Section 2.

- **authN** - short for authentication.

- **authZ** - short for authorization.

**New Terms**

- **GS URI** - the endpoint at the GS the GC calls to create a Grant, and is the unique identifier for the GS.

- **Registered Client** - a GC that has registered with the GS and has a Client ID to identify itself, and can prove it possesses a key that is linked to the Client ID. The GS may have different policies for what different Registered Clients can request. A Registered Client MAY be interacting with a User.

- **Dynamic Client** - a GC that has not been previously registered with the GS, and each instance will generate it's own asymetric key pair so it can prove it is the same instance of the GC on subsequent requests. The GS MAY return a Dynamic Client a Client Handle for the Dynamic Client to identify itself in subsequent requests. A single-page application with no active server component is an example of a Dynamic Client.

- **Client Handle** - a unique identifier at the GS for a Dynamic Client for the Dynamic Client to refer to itself in subsequent requests.

- **Interaction** - how the GC directs the User to interact with the GS. This document defines the interaction modes: "redirect", "indirect", and "user_code" in {{InteractionModes}}.

- **Grant** - the user identity claims and/or resource access the GS has granted to the Client. The GS MAY invalidate a Grant at any time.

- **Grant URI**  - the URI that represents the Grant. The Grant URI MUST start with the GS URI.

- **Access** - the access granted by the RO to the GC and contains an access token. The GS may invalidate an Access at any time.

- **Access URI** - the URI that represents the Access the GC was granted by the RO. The Access URI MUST start with the GS URI. The Access URI is used to refresh an access token.

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
specification are to be interpreted as described in {{RFC2119}}.

Certain security-related terms are to be understood in the sense
defined in {{RFC4949}}.  These terms include, but are not limited to,
"attack", "authentication", "authorization", "certificate",
"confidentiality", "credential", "encryption", "identity", "sign",
"signature", "trust", "validate", and "verify".

*\[Editor: review that the terms listed and used are the same]*

Unless otherwise noted, all the protocol parameter names and values
are case sensitive. 

Some protocol parameters are parts of a JSON document, and are referred to in JavaScript notation. For example, `foo.bar` refers to the "bar" boolean attribute in the "foo" object in the following example JSON document:

    {
        "foo" : {
            "bar": true
        }
    }

# Exemplar Sequences

The following sequences are demonstrative of how GNAP can be used, but are just a few of the possible sequences possible with GNAP.

Before any sequence, the GC needs to be manually or programmatically configured for the GS. See GS Options 
{{GSoptions}} for details on programmatically acquiring GS metadata.

In the sequence diagrams:

    + + + indicates an interaction with a person
    ----- indicates an interaction between protocol roles


## "redirect" Interaction

The GC is a web application and wants a Grant from the User containing resource access and identity claims. The User is the RO for the resource:

    +--------+                                  +--------+
    | Grant  |                                  | Grant  |
    | Client |--(1)--- Create Grant ----------->| Server |
    |  (GC)  |                                  |  (GS)  |
    |        |<--- Interaction Response ---(2)--|        |         +------+
    |        |                                  |        |         | User |
    |        |+ +(3)+ + Interaction Transfer + +| + + + +|+ + + + >|      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (4) +>|      |
    |        |                                  |        |  authN  |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (5) +>|      |
    |        |                                  |        |  authZ  |      |
    |        |<+ + Interaction Transfer + +(6)+ | + + + +|+ + + + +|      |
    |        |                                  |        |         |      |
    |        |--(7)--- Verify Grant ----------->|        |         +------+
    |        |                                  |        |
    |        |<--------- Grant Response ---(8)--|        |
    |        |                                  |        |
    +--------+                                  +--------+
 
1. **Create Grant** The GC creates a Request JSON document {{RequestJSON}} containing an interaction.redirect object, and the requested identity claims and resource access. The GC then makes a Create Grant request ({{CreateGrant}}) by sending the JSON with an HTTP POST to the GS URI.

2. **Interaction Response**  The GS determines that interaction with the User is required and sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI and an interaction.redirect object containing the redirect_uri.

3. **Interaction Transfer** The GC redirects the User to the redirect_uri at the GS.

4. **User Authentication** The GS authenticates the User.

5. **User Authorization** If required, the GS interacts with the User (who may also be the RO) to determine the identity claims and resource access in the Grant Request are to be granted.

6. **Interaction Transfer** The GS redirects the User to the completion_uri at the GC. 

7. **Verify Grant** The GC makes an HTTP PATCH request to the Grant URI passing the verification code ({{VerifyGrant}}).

8. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).

The GC can now access the resources at the RS per {{RSA}}.

## "user_code" Interaction

A GC is on a device that wants a Grant from the User. The User will interact with the GS using a separate device:

    +--------+                                  +--------+
    | Grant  |                                  | Grant  |
    | Client |--(1)--- Create Grant ----------->| Server |
    |  (GC)  |                                  |  (GS)  |
    |        |<--- Interaction Response ---(2)--|        |         +------+
    |        |                                  |        |         | User |
    |        |--(3)--- Read Grant ------------->|        |         |      |
    |        |                                  |        |<+ (4) +>|      |
    |        |                                  |        |  authN  |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (5) +>|      |
    |        |                                  |        |  code   |      |
    |        |                                  |        |         |      |
    |        |                                  |        |<+ (6) +>|      |
    |        |                                  |        |  authZ  |      |
    |        |                                  |        |         |      |
    |        |<--------- Grant Response ---(7)--|        |         |      |
    |        |                                  |        |         |      |
    +--------+                                  |        |         |      |
                                                |        |         |      |
    +--------+                                  |        |         |      |
    | Client |< + + Information URI Redirect + +| + + + +|+ (8) + +|      |
    | Server |                                  |        |         |      |
    +--------+                                  +--------+         +------+

1. **Create Grant** The GC creates a Request JSON document {{RequestJSON}} containing an interaction.user_code object and makes a Create Grant request ({{CreateGrant}}) by sending the JSON with an HTTP POST to the GS URI.

2. **Interaction Response**  The GS determines that interaction with the User is required and sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI and an interaction.user_code object.

3. **Read Grant** The GC makes an HTTP GET request to the Grant URI.

4. **User Authentication** The User loads display_uri in their browser, and the GS authenticates the User.

5. **User Code** The User enters the code at the GS.

6. **User Authorization** If required, the GS interacts with the User (who may also be the RO) to determine the identity claims and resource access in the Grant Request are to be granted.

7. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).

8. **Information URI Redirect** The GS redirects the User to the information_uri provided by the GC.

The GC can now access the resources at the RS per {{RSA}}.

## Independent RO Authorization

The GC wants access to resources that require the GS to interact with the RO, who is not interacting with the GC. The authorization from the RO may take some time, so the GS instructs the GC to wait and check back later.

    +--------+                                  +--------+
    | Grant  |                                  | Grant  |
    | Client |--(1)--- Create Grant ----------->| Server |
    |  (GC)  |                                  |  (GS)  |
    |        |<---------- Wait Response ---(2)--|        |         +------+
    |  (3)   |                                  |        |         |  RO  |
    |  Wait  |                                  |        |<+ (4) +>|      |
    |        |                                  |        |  authZ  |      |
    |        |--(5)--- Read Grant ------------->|        |         +------+
    |        |                                  |        |
    |        |<--------- Grant Response --(6)---|        |
    |        |                                  |        |
    +--------+                                  +--------+

1. **Create Grant** The GC creates a Grant Request ({{CreateGrant}}) and sends it with an HTTP POST to the GS GS URI.

2. **Wait Response**  The GS sends an Wait Response ({{WaitResponse}}) containing the Grant URI and the "wait" attribute.

3. **GC Waits** The GC waits for the time specified in the "wait" attribute.

4. **RO AuthZ** The GS interacts with the RO to determine which identity claims and/or resource access in the Grant Request are to be granted. 

5. **Read Grant** The GC does an HTTP GET of the Grant URI ({{ReadGrant}}).

6. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).

The GC can now access the resources at the RS per {{RSA}}.

## Resource Server Access {#RSA}

The GC received an Access URI from the GS. The GC acquires an access token, calls the RS, and later the access token expires. The GC then gets a fresh access token.


    +--------+                             +----------+  +--------+
    | Grant  |                             | Resource |  | Grant  |
    | Client |--(1)--- Access Resource --->|  Server  |  | Server | 
    |  (GC)  |<------- Resource Response --|   (RS)   |  |  (GS)  | 
    |        |                             |          |  |        | 
    |        |--(2)--- Access Resource --->|          |  |        | 
    |        |<------- Error Response -----|          |  |        |
    |        |                             |          |  |        | 
    |        |                             +----------+  |        |
    |        |                                           |        |
    |        |--(3)--- Read Access --------------------->|        |
    |        |<------- Access Response ------------------|        |
    |        |                                           |        |
    +--------+                                           +--------+

1. **Resource Request** The GC accesses the RS with the access token per {{RSAccess}} and receives a response from the RS.

2. **Resource Request** The GC attempts to access the RS, but receives an error indicating the access token needs to be refreshed. 

3. **Read Access** The GC makes a Read Access ({{ReadAccess}}) with an HTTP GET to the Access URI and receives as Response JSON "access" object ({{ResponseAccessObject}}) with a fresh access token.



# GS APIs

**GC Authentication**

All GS APIs except for GS Options require the GC to authenticate. Authentication mechanisms include:

+ JOSE Authentication {{JOSE Authentication}}

+ \[Others TBD]*


## GS API Table

| request            | http method | uri          | response     
|:---                |---          |:---          |:--- 
| Create Grant       | POST        | GS URI       | Interaction, wait, or Grant 
| Verify Grant       | PATCH       | Grant URI    | Grant 
| Read Grant         | GET         | Grant URI    | wait, or Grant 
| Read Access        | GET         | Access URI   | Access 
| GS Options         | OPTIONS     | GS URI       | metadata 


## Create Grant {#CreateGrant}

The GC creates a Grant by doing an HTTP POST of a JSON {{RFC8259}} document to the GS URI. This is a Grant Request.

The JSON document MUST include the following from the Request JSON {{RequestJSON}}:

+ iat
+ nonce
+ uri - MUST be set to the GS URI
+ method - MUST be "POST"
+ client

and MAY include the following from Request JSON {{RequestJSON}}

+ user
+ interaction
+ access
+ claims

The GS MUST respond with one of Grant Response {{GrantResponse}}, Interaction Response {{InteractionResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

Following is a non-normative example of a web application GC requesting identity claims about the User and read access to the User's contacts:

    Example 1

    { 
        "iat"       : 15790460234,
        "uri"       : "https://as.example/endpoint",
        "method"    : "POST,  
        "nonce"     : "f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "client": {
            "display": {
                "name"  : "SPA Display Name",
                "uri"   : "https://spa.example/about"
            }
        },
        "interaction": {
            "redirect": {
                "completion_uri"    : "https://web.example/return"
            },
            "global" : {
                "ui_locals" : "de"
            }
        },
        "access": [ "read_contacts" ],
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


Following is a non-normative example of a device GC requesting two different access tokens, one request with "oauth_scope", the other with "oauth_rich":

    Example 2

    { 
        "iat"       : 15790460234,
        "uri"       : "https://as.example/endpoint",
        "method"    : "POST,  
        "nonce"     : "5c9360a5-9065-4f7b-a330-5713909e06c6",
        "client": {
            "id"        : "di3872h34dkJW"
        },
        "interaction": {
            "indirect": {
                "information_uri": "https://device.example/c/indirect"
            },
            "user_code": {
                "information_uri": "https://device.example/c/user_code"
             }
        },
        "access": {
            "play_music": [ "play_music" ],
            "read_user_info: [ {
                "type"      : "customer_information",
                "locations" : [ "https://example.com/customers" ],
                "actions"   : [ "read" ],
                "datatypes" : [ "contacts", "photos" ]
            } ]
        }
    }


## Verify Grant {#VerifyGrant}

The GC verifies a Grant by doing an HTTP PATCH of a JSON document to the Grant URI. The GC MUST only verify a Grant once. 

The JSON document MUST include the following from the Request JSON {{RequestJSON}}:

+ iat
+ nonce
+ uri - MUST be set to the Grant URI
+ method - MUST be PATCH
+ interaction.redirection.verification - MUST be the verification code received per {{RedirectVerification}}.

Following is a non-normative example:

    { 
        "iat"     : 15790460235,
        "uri"     : "https://as.example/endpoint/grant/example1",
        "method"  : "PATCH,  
        "nonce"   : "9b6afd70-2036-47c9-b953-5dd1fd0c699a",
        "interaction": {
            "redirect": {
                "verification" : "cb4aa22d-2fe1-4321-b87e-bbaa66fbe707"
            }
        }
    }

The GS MUST respond with one of Grant Response {{GrantResponse}} or one of the following errors:

+ TBD

## Read Grant {#ReadGrant}

The GC reads a Grant by doing an HTTP GET of the corresponding Grant URI. The GC MAY read a Grant until it expires or has been invalidated.

The GS MUST respond with one of Grant Response {{GrantResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

+ TBD 

## Request JSON {#RequestJSON}

+ **iat** - the time of the request as a NumericDate.

+ **nonce** - a unique identifier for this request. Note the Grant Response MUST contain a matching "nonce" attribute value.

+ **uri** - the URI being invoked

+ **method** - the HTTP method being used

### "client" Object
The client object MUST only one of the following:

+ **id** - the Client ID the GS has for a Registered Client.

+ **handle** - the Client Handle the GS previously provided a Dynamic Client

+ **display** - the display object contains the following attributes:

    + **name** - a string that represents the Dynamic Client

    + **uri** - a URI representing the Dynamic Client 


The GS will show the the User the display.name and display.uri values when prompting for authorization.

*\[Editor: a max length for the name and URI so a GS can reserve appropriate space?]*

### "interaction" Object

The interaction object contains one or more interaction mode objects per {{InteractionModes}} representing the interactions the GC is willing to provide the User. In addition to the interaction mode objects, the interaction object may contain the "global" object;

+ **global** - an optional object containing parameters that are applicable for all interaction modes. Only one attribute is defined in this document:

    + **ui_locales** - End-User's preferred languages and scripts for the user interface, represented as a space-separated list of {{RFC5646}} language tag values, ordered by preference. This attribute is OPTIONAL.


*\[Editor: ui_locales is taken from OIDC. Why space-separated and not a JSON array?]*


### "user" Object {#RequestUserObject}

+ **identifiers** - The identifiers MAY be used by the GS to improve the User experience. This object contains one or more of the following identifiers for the User:

    + **phone_number** - contains a phone number per Section 5 of {{RFC3966}}.

    + **email** - contains an email address per {{RFC5322}}.

    + **oidc** - is an object containing both the "iss" and "sub" attributes from an OpenID Connect ID Token {{OIDC}} Section 2. 

+ **claims** - an optional object containing one or more assertions the GC has about the User. 

    + **oidc_id_token** - an OpenID Connect ID Token per {{OIDC}} Section 2.

### "access" Object {#AccessObject}
The GC may request a single Access, or multiple. If a single Access, the "access" object contains an array of {{RAR}} objects. If multiple, the "access" object
contains an object where each property name is a unique string created by the GC, and the property value is an array of {{RAR}} objects.

### "claims" Object {#ClaimsObject}

Includes one or more of the following:

+ **oidc** - an object that contains one or both of the following objects:

    - **userinfo** - Claims that will be returned as a JSON object 

    - **id_token** - Claims that will be included in the returned ID Token. If the null value, an ID Token will be returned containing no additional Claims. 

The contents of the userinfo and id_token objects are Claims as defined in {{OIDC}} Section 5. 

+ **oidc4ia** - OpenID Connect for Identity Assurance claims request per {{OIDC4IA}}.

+ **vc** - *\[Editor: define how W3C Verifiable Credentials {{W3C VC}} can be requested.]*


## Read Access {#ReadAccess}

The GC acquires and refreshes an Access by doing an HTTP GET to the corresponding Access URI.

The GS MUST respond with a Access JSON document {{AccessJSON}}, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

## GS Options {#GSoptions}

The GC can get the metadata for the GS by doing an HTTP OPTIONS of the corresponding GS URI. This is the only API where the GS MAY respond to an unauthenticated request.

The GS MUST respond with the the following JSON document:


+ **uri** - the GS URI.

+ **client_authentication** - a JSON array of the GC Authentication mechanisms supported by the GS

+ **interactions** - a JSON array of the interaction modes supported by the GS.

+ **access** - an object containing the access the GC may request from the GS, if any.

    + Details TBD

+ **claims** - an object containing the identity claims the GC may request from the GS, if any, and what public keys the claims will be signed with.

    + Details TBD

+ **algorithms** - a JSON array of the cryptographic algorithms supported by the GS. \[details TBD]*

+ **features** - an object containing feature or extension support


or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.


# GS Responses

There are three successful responses to a Grant Request: Grant Response, Interaction Response, or Wait Response. 

## Grant Response {#GrantResponse}

The Grant Response MUST include the following from the Response JSON {{ResponseJSON}}

+ iat
+ nonce
+ uri

and MAY include the following from the Response JSON {{ResponseJSON}}

+ client.handle
+ access
+ claims
+ expires_in
+ warnings

Example non-normative Grant Response JSON document for Example 1 in {{CreateGrant}}:

    { 
        "iat"           : 15790460234,
        "nonce"         : "f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "uri"           : "https://as.example/endpoint/grant/example1",
        "expires_in"    : 300
        "access": {
            "mechanism"     : "bearer",
            "token"         : "eyJJ2D6.example.access.token.mZf9p"
            "expires_in"    : 3600,
            "granted"       : [ "read_contacts" ],
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

Note in this example since no Access URI was returned in the access object, the access token can not be refreshed, and expires in an hour.

Example non-normative Grant Response JSON document for Example 2 in {{CreateGrant}}:

    {
        "iat"   : 15790460234,
        "nonce" : "5c9360a5-9065-4f7b-a330-5713909e06c6",
        "uri"   : "https://as.example/endpoint/grant/example2",
        "access": {
            "play_music": { "uri"       : "https://as.example/endpoint/access/example2" },
            "read_user_info: { "uri"    " "https://as.example/endpoint/access/"}
        }
    }

Note in this example the GS only provided the Access URIs. The GC must acquire the Access per {{ReadAccess}}

\[Editor: the GC needs to remember if it asked for a single access, or multiple, as there is no crisp algorithm for differentiating between the responses]

## Interaction Response {#InteractionResponse}

The Interaction Response MUST include the following from the Response JSON {{ResponseJSON}}

+ iat
+ nonce
+ uri
+ interaction

and MAY include the following from the Response JSON {{ResponseJSON}}

+ user
+ wait
+ warnings

A non-normative example of an Interaction Response follows:

    {
        "iat"       : 15790460234,
        "nonce"     : "0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "uri"       : "https://as.example/endpoint/grant/example4",
        "interaction" : {
            "redirect" : {
                "redirect_uri"     : "https://as.example/i/example4"
            }
        }    
    }


## Wait Response {#WaitResponse}

The Wait Response MUST include the following from the Response JSON {{ResponseJSON}}

+ iat
+ nonce
+ uri
+ wait

and MAY include the following from the Response JSON {{ResponseJSON}}

+ warnings

A non-normative example of Wait Response follows:

    {
        "iat"       : 15790460234,
        "nonce"     : "0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "uri"       : "https://as.example/endpoint/grant/example5",
        "wait"      : 300
    }

## Response JSON {#ResponseJSON}

Details of the JSON document: 

+ **iat** - the time of the response as a NumericDate.

+ **nonce** - the nonce that was included in the Request JSON {{RequestJSON}}.

+ **uri** - the Grant URI.

+ **wait** - a numeric value representing the number of seconds the GC should want before making a Read Grant request to the Grant URI.

+ **expires_in** - a numeric value specifying how many seconds until the Grant expires. This attribute is OPTIONAL.

### "client" Object {#clientObject}

If the GC is a Dynamic Client, the GS may return

+ **handle** the Client Handle

### "interaction" Object {#interactionObject}

If the GS wants the GC to start the interaction, the GS MUST return an interaction object containing one or more interaction mode responses per {{InteractionModes}} to one or more of the interaction mode requests provided by the GC. 

### "access" Object

If the GC requested a single Access, the "access" object is an access response object {{ResponseAccessObject}}. If the GC requested multiple, the access object contains a property of the same name for each Access requested by the GC, and each property is an access response object {{ResponseAccessObject}}.

### Access Response Object {#ResponseAccessObject}

The access response object contains properties from the Access JSON {{AccessJSON}}. The access response object MUST contain either the "uri" property from, or MUST contain:

+ mechanism
+ token

and MAY contain:

+ access
+ expires_in
+ uri

If there is no "uri" property, the access token can not be refreshed. If only the "uri" property is present, the GC MUST acquire the Access per {{ReadAccess}}

### "claims" Object {#ResponseClaimsObject}

The claims object is a response to the Grant Request "claims" object {{ClaimsObject}}.

+ **oidc**

    - **id_token** - an OpenID Connect ID Token containing the Claims the User consented to be released.
    - **userinfo** - the Claims the User consented to be released.

    Claims are defined in {{OIDC}} Section 5.

+ **oidc4ia** - OpenID Connect for Identity Assurance claims response per {{OIDC4IA}}.

+ **vc**

    The verified claims the user consented to be released. *\[Editor: details TBD]*

### "warnings" JSON Array {#WarningsObject}

Includes zero or more warnings from {{Warnings}},

## Access JSON {#AccessJSON}

The Access JSON is a Grant Response Access Object {{ResponseAccessObject}} or the response to a Read Access request by the GC {{ReadAccess}}.


+ **mechanism** - the RS access mechanism. This document defines the "bearer" mechanism as defined in {{RSAccess}}. Required.

+ **token** - the access token for accessing an RS. Required.

+ **expires_in** - an optional numeric value specifying how many seconds until the access token expires.

+ **uri** - the Access URI. Used to acquire or refresh Access. Required.

+ **granted** - an optional array of {{RAR}} objects containing the resource access granted

*\[Editor: would an optional expiry for the Access be useful?]*

The following is a non-normative example of Access JSON:

    {
        "mechanism"     : "bearer",
        "token"         : "eyJJ2D6.example.access.token.mZf9p"
        "expires_in"    : 3600,
        "uri"           : "https://as.example/endpoint/access/example2",
        "granted"       : [ "read_calendar write_calendar" ]
    }

## Response Verification

On receipt of a response, the GC MUST verify the following:

+ TBD

# Interaction Modes {#InteractionModes}

This document defines three interaction modes: "redirect", "indirect", and "user_code". Extensions may define additional interaction modes.

The "global" attribute is reserved in the interaction object for attributes that apply to all interaction modes.

## "redirect" 

A Redirect Interaction is characterized by the GC redirecting the User's browser to the GS, the GS interacting with the User, and then GS redirecting the User's browser back to the GC. The GS correlates the Grant Request with the unique redirect_uri, and the GC correlates the Grant Request with the unique completion_uri.


**The request "interaction" object contains:**

+ **completion_uri**  a unique URI at the GC that the GS will return the User to. The URI MUST not contain the "nonce" from the Grant Request, and MUST not be guessable. This attribute is REQUIRED.


**The response "interaction" object contains:**

+ **redirect_uri** a unique URI at the GS that the GC will redirect the User to. The URI MUST not contain the "nonce" from the Grant Request, and MUST not be guessable. This attribute is REQUIRED.

+ **verification** a boolean value indicating the GS requires the GC to make a Verify Grant request.({{VerifyGrant}})

### "redirect" verification {#RedirectVerification}

If the GS indicates that Grant Verification is required, the GS MUST add a 'verification' query parameter with a value of a unique verification code to the completion_uri.

On receiving the verification code in the redirect from the GS, the GC makes a Verify Grant request ({{VerifyGrant}}) with the verification code. 

## "indirect" 

An Indirect Interaction is characterized by the GC causing the User's browser to load the indirect_uri at GS, the GS interacting with the User, and then the GS MAY optionally redirect the User's Browser to a information_uri. There is no mechanism for the GS to redirect the User's browser back to the GC.

 Examples of how the GC may initiate the interaction are encoding the indirect_uri as a code scannable by the User's mobile device, or launching a system browser from a command line interface (CLI) application.

The "indirect" mode is susceptible to session fixation attacks. See TBD in the Security Considerations for details.

**The request "interaction" object contains:**

+ **information_uri** an OPTIONAL URI that the GS will redirect the User's browser to after GS interaction.


**The response "interaction" object contains:**

+ **indirect_uri** the URI the GC will cause to load in the User's browser. The URI SHOULD be short enough to be easily encoded in a scannable code. The URI MUST not contain the "nonce" from the Grant Request, and MUST not be guessable. *\[Editor: recommend a maximum length?]*

## "user_code" 

An Indirect Interaction is characterized by the GC displaying a code and a URI for the User to load in a browser and then enter the code.  *\[Editor: recommend a minimum entropy?]*

**The request "interaction" object contains:**

+ **information_uri** an OPTIONAL URI that the GS will redirect the User's browser to after GS interaction.


**The response "interaction" object contains:**

+ **code** the code the GC displays to the User to enter at the display_uri. This attribute is REQUIRED.

+ **display_uri** the URI the GC displays to the User to load in a browser to enter the code.


# RS Access {#RSAccess}

The mechanism the GC MUST use to access an RS is in the Access JSON "mechanism" attribute {{ResponseAccessObject}}.

The "bearer" mechanism is defined in Section 2.1 of {{RFC6750}}

The "jose" and "jose+body" mechanisms are defined in {{JOSE Authentication}}

A non-normative "bearer" example of the HTTP request headers follows:

    GET /calendar HTTP/2
    Host: calendar.example
    Authorization: bearer eyJJ2D6.example.access.token.mZf9pTSpA


# Error Responses {#ErrorResponses}

+ TBD

# Warnings {#Warnings}

\[Editor: Warnings are an optional response that can assist a GC in detecting non-fatal errors, such as ignored objects and properties.]

+ TBD

# Extensibility {#Extensibility}

This standard can be extended in a number of areas:

+ **GC Authentication Mechanisms**

    + An extension could define other mechanisms for the GC to authenticate to the GS and/or RS such as Mutual TLS or HTTP Signing. Constrained environments could use CBOR {{RFC7049}} instead of JSON, and COSE {{RFC8152}} instead of JOSE, and CoAP {{RFC8323}} instead of HTTP/2.

+ **Grant**

    + An extension can define new objects in the Grant Request and Grant Response JSON that return new URIs. 

+ **Top Level**

    + Top level objects SHOULD only be defined to represent functionality other the existing top level objects and attributes.

+ **"client" Object**

    + Additional information about the GC that the GS would require related to an extension.

+ **"user" Object**

    + Additional information about the User that the GS would require related to an extension.

+ **"access" Object**

    + RAR is inherently extensible.

+ **"claims" Object**

    + Additional claim schemas in addition to OpenID Connect claims and Verified Credentials.

+ **interaction modes**

   + Additional types of interactions a GC can start with the User.


+ **Continuous Authentication**

    + An extension could define a mechanism for the GC to regularly provide continuous authentication signals and receive responses.

*\[Editor: do we specify access token introspection in this document, or leave that to an extension?]*


# Rational

1. **Why do GCs now always use Asymetric cryptography? Why not keep the client secret?**

    In the past, asymetric cryptography was relatively computational expensive. Modern browsers now have asymetric cryptographic APIs available, and modern hardware has significantly reduced the computational impact. 

1. **Why have both Client ID and Client Handle?**

    While they both refer to a Grant Client in the protocol, the Client ID refers to a pre-registered client,and the Client Handle is specific to an instance of a Dynamic Client. Using separate terms clearly differentiates which identifier is being presented to the GS. 


1. **Why allow GC and GS to negotiate the user interaction mode?**

    The GC knows what interaction modes it is capable of, and the GS knows which interaction modes it will permit for a given Grant Request. The GC can then present the intersection to the User to choose which one is preferred. For example, while a device based GC may be willing to do both "indirect" and "user_code", a GS may not enable "indirect" for concern of a session fixation attack. Additional interaction modes will likely become available which allows new modes to be negotiated between GC and GS as each adds additional interaction modes.

1. **Why have both identity claims and resource access?**

    There are use cases for each that are independent: authenticating a user and providing claims vs granting access to a resource. A request for an authorization returns an access token which may have full CRUD capabilities, while a request for a claim returns the claim about the User -- with no create, update or delete capabilities. While the UserInfo endpoint in OIDC may be thought of as a resource, separating the concepts and how they are requested keeps each of them simpler in the Editor's opinion. :)

1. **Why do some of the JSON objects only have one child, such as the identifiers object in the user object in the Grant Request?**

    It is difficult to forecast future use cases. Having more resolution may mean the difference between a simple extension, and a convoluted extension. For example, the "global" object in the "interaction" object allows new global parameters to be added without impacting new interaction modes.


1. **Why is the "iss" included in the "oidc" identifier object? Would the "sub" not be enough for the GS to identify the User?**

    This decouples the GS from the OpenID Provider (OP). The GS identifier is the GS URI, which is the endpoint at the GS. The OP issuer identifier will likely not be the same as the GS URI. The GS may also provide claims from multiple OPs.

1. **Why is there not a UserInfo endpoint as there is with OpenID Connect?**

    Since the GC can Read Grant at any time, it get the same functionality as the UserInfo endpoint, without the GC having to manage a separate access token and refresh token. If the GC would like additional claims, it can Update Grant, and the GS will let the GC know if an interaction is required to get any of the additional claims, which the GC can then start. 
       
    *\[Editor: is there some other reason to have the UserInfo endpoint?]*

1. **Why use URIs for the Grant and Access?**
    
    + Grant URI and Access URI are defined to start with the GS URI, allowing the GC, and GS to determine which GS a Grant or Access belongs to.

    + URIs also enable a RESTful interface to the GS functionality.

    + A large scale GS can easily separate out the services that provide functionality as routing of requests can be done at the HTTP layer based on URI and HTTP method. This allows a separation of concerns, independent deployment, and resiliency.


1. **Why use the OPTIONS method on the GS URI? Why not use a .well-known mechanism?**

    Having the GS URI endpoint respond to the metadata allows the GS to provide GC specific results using the same GC authentication used for other requests to the GS. It also reduces the risk of a mismatch between the advertised metadata, and the actual metadata. A .well-known discovery mechanism may be defined to resolve from a hostname to the GS URI.

1. **Why is there a Verify Grant? The GC can protect itself from session fixation without it.**

    GC implementations may not always follow the best practices. The Verify Grant allows the GS to ensure there is not a session fixation as the instance of the GC making creating the Grant is the one that gets the verification code in the redirect.

1. **Why use the {{OIDC}} claims rather than the {{IANA JWT}} list of claims?

    The {{IANA JWT}} claims include claims that are not identity claims, and {{IANA JWT}} references the {{OIDC}} claims, and {{OIDC}} 5.1 are only identity claims.


# Privacy Considerations

TBD

# Security Considerations

TBD

# Acknowledgments

This draft derives many of its concepts from Justin Richer's Transactional Authorization draft {{TxAuth}}. 

Additional thanks to Justin Richer and Annabelle Richard Backman for their strong critique of earlier drafts.
\[Editor: add in the other contributors from mail list]

# IANA Considerations

TBD

--- back

# Document History

## draft-hardt-xauth-protocol-00

- Initial version

## draft-hardt-xauth-protocol-01

- text clean up
- added OIDC4IA claims
- added "jws" method for accessing a resource.
- renamed Initiation Request -> Grant Request
- renamed Initiation Response -> Interaction Response
- renamed Completion Request -> Authorization Request
- renamed Completion Response -> Grant Request
- renamed completion handle -> authorization handle
- added Authentication Request, Authentication Response, authentication handle

## draft-hardt-xauth-protocol-02

- major rewrite
- handles are now URIs
- the collection of claims and authorizations are a Grant
- an Authorization is its own type
- lots of sequences added

## draft-hardt-xauth-protocol-03

- fixed RO definition
- improved language in Rationals
- added user code interaction method, and aligned qrcode interaction method
- added information_uri for code flows

## draft-hardt-xauth-protocol-04

- renamed interaction uris to have purpose specific names

## draft-hardt-xauth-protocol-05

- separated claims from identifiers in request user object
- simplified reciprocal grant flow
- reduced interactions to redirect and indirect
- simplified interaction parameters
- added in language for Client to verify interaction completion
- added Verify Grant API and Interaction Nonce
- replaced Refresh AuthZ with Read AuthZ. Read and refresh are same operation.

## draft-hardt-xauth-protocol-06

- fixup examples to match specification

## draft-hardt-xauth-protocol-07

- refactored interaction request and response syntax, and enabled interaction mode negotiation
- generation of client handle by GS for dynamic clients
- renamed title to Grant Negotiation and Authorization Protocol. Preserved draft-hardt-xauth-protocol filename to ease tracking changes.
- changed Authorizations to be key / value pairs (aka dictionary) instead of a JSON array

## draft-hardt-xauth-protocol-08
- split document into three documents: core, advanced, and JOSE authentication.
- grouped access granted into "access" object in Authorization JSON
- added warnings object to the Grant Response JSON

## draft-hardt-xauth-protocol-09
- added editorial note that this document should be referred to as XAuth

## draft-hardt-xauth-protocol-10
- added example of RAR authorization request
- fixed typos

## draft-hardt-xauth-protocol-11
- renamed authorization_uri to interaction_uri to avoid confusion with AZ URI
- made URI names more consistent
    - renamed completion_uri to information_uri
    - renamed redirect_uri to completion_uri
    - renamed interaction_uri to redirect_uri
    - renamed short_uri to indirect_uri
- editorial fixes
- renamed http verb to method
- added Verify Grant and verification parameters

## draft-hardt-xauth-protocol-12
- removed authorization object, and made authorizations object polymorphic

## draft-hardt-xauth-protocol-13
- added Q about referencing OIDC claims vs IANA JWT
- made all authorizations be a RAR type as it provides the required flexibility, removed "oauth_rar" type
- added RO to places where the RO and User are the same

## draft-hardt-xauth-protocol-14
- add in claims issuer
- abstract protocol
- add clarification on different parties
- renamed Client to Grant Client
- added entity relationship diagram
- updated diagrams
- added placeholder for Privacy Considerations
- renamed Authorization to Access

# Comparison with OAuth 2.0 and OpenID Connect

**Changed Features**

The major changes between GNAP and OAuth 2.X and OpenID Connect are:

+ The OAuth 2.X client and the OpenID Connect replying party are the Grant Client in GNAP.

+ The GNAP Grant Server is a superset of the OAuth 2.X authorization server, and the OpenID Connect OP (OpenID Provider). 

+ The GC always uses a private asymetric key to authenticate to the GS. There is no client secret.

+ The GC initiates the protocol by making a signed request directly to the GS instead of redirecting the User to the GS.

+ The GC does not pass any parameters in redirecting the User to the GS.

+ The refresh_token has been replaced with an AZ URI that both represents the authorization, and is the URI for obtaining a fresh access token.

+ The GC can request identity claims to be returned independent of the ID Token.

+ The GS URI is the only static endpoint. All other URIs are dynamically generated. The GC does not need to register it's redirect URIs.

TBD - negotiation

**Preserved Features** 

+ GNAP reuses the scopes, Client IDs, and access tokens of OAuth 2.0. 

+ GNAP reuses the Client IDs, Claims and ID Token of OpenID Connect.

+ No change is required by the GC or the RS for accessing existing bearer token protected APIs.

**New Features**

+ All GC calls to the GS are authenticated with asymetric cryptography

+ A Grant represents both the user identity claims and RS access granted to the GC.

+ Support for scannable code initiated interactions.

+ Highly extensible per {{Extensibility}}.
