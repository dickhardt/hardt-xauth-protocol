---
docname: draft-hardt-xauth-protocol-10
title: The Grant Negotiation and Authorization Protocol
date: 2020-06-08
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


--- abstract 

Client software often desires resources or identity claims that are independent of the client. This protocol allows a user and/or resource owner to delegate resource authorization and/or release of identity claims to a server. Client software can then request access to resources and/or identity claims by calling the server. The server acquires consent and authorization from the user and/or resource owner if required, and then returns to the client software the authorization and identity claims that were approved. This protocol may be extended to support alternative authorizations, claims, interactions, and client authentication mechanisms.

--- middle

# Introduction

**EDITOR NOTE**

*This document captures a number of concepts that may be adopted by the proposed GNAP working group. Please refer to this document as:* 

**XAuth**

*The use of GNAP in this document is not intended to be a declaration of it being endorsed by the proposed GNAP working group.* 

This document describes the core Grant Negotiation and Authorization Protocol (GNAP). The protocol supports the widely deployed use cases supported by OAuth 2.0 {{RFC6749}} & {{RFC6750}}, OpenID Connect {{OIDC}} - an extension of OAuth 2.0, as well as other extensions. Related documents include: GNAP - Advanced Features {{GNAP Advanced}} and JOSE Authentication {{JOSE Authentication}} that describes the JOSE mechanisms for client authentication. 

The technology landscape has changed since OAuth 2.0 was initially drafted. More interactions happen on mobile devices than PCs. Modern browsers now directly support asymetric cryptographic functions. Standards have emerged for signing and encrypting tokens with rich payloads (JOSE) that are widely deployed.

GNAP simplifies the overall architectural model, takes advantage of today's technology landscape, provides support for all the widely deployed use cases, offers numerous extension points, and addresses many of the security issues in OAuth 2.0 by passing parameters securely between parties, rather than via a browser redirection. . 

While GNAP is not backwards compatible with OAuth 2.0, it strives to minimize the migration effort.

GNAP centers around a Grant, a representation of the collection of user identity claims and/or resource authorizations the Client is requesting, and the resulting identity claims and/or resource authorizations granted by the Grant Server (GS).

User consent is often required at the GS. GNAP enables a Client and GS to negotiate the interaction mode for the GS to obtain consent. 

The suggested pronunciation of GNAP is the same as the English word "nap", a silent "g" as in "gnaw". 

*\[Editor: suggestions on how to improve this are welcome!]*


## Parties

The parties and their relationships to each other:

        +--------+                           +------------+
        |  User  |                           |  Resource  |
        |        |                           | Owner (RO) |
        +--------+                           +------------+
            |      \                       /      |
            |       \                     /       |
            |        \                   /        |
            |         \                 /         |
        +--------+     +---------------+     +------------+
        | Client |---->|     Grant     |     |  Resource  |
        |        | (1) |  Server (GS)  | _ _ |   Server   |
        |        |<----|               |     |    (RS)    |
        |        |     +---------------+     |            |
        |        |-------------------------->|            |
        |        |           (2)             |            |
        |        |<--------------------------|            |
        +--------+                           +------------+

This document specifies interactions between the Client and GS (1), and the Client and RS (2).

- **User** - the person interacting with the Client who has delegated access to identity claims about themselves to the Grant Server (GS), and can authenticate at the GS.

- **Client** - requests a Grant from the GS to access one or more Resource Servers (RSs), and/or identity claims about the User. The Grant may include access tokens that the Client uses to access the RS. There are two types of Clients: Registered Clients and Dynamic Clients. All Clients have a private asymetric key to authenticate with the Grant Server. 

- **Registered Client** - a Client that has registered with the GS and has a Client ID to identify itself, and can prove it possesses a key that is linked to the Client ID. The GS may have different policies for what different Registered Clients can request. A Registered Client MAY be interacting with a User.

- **Dynamic Client** - a Client that has not been previously registered with the GS, and each instance will generate it's own asymetric key pair so it can prove it is the same instance of the Client on subsequent requests. The GS MAY return a Dynamic Client a Client Handle for the Client to identify itself in subsequent requests. A single-page application with no active server component is an example of a Dynamic Client. A Dynamic Client MUST be interacting with a User.

- **Grant Server** (GS) - manages Grants for access to APIs at RSs and release of identity claims about the User. The GS may require explicit consent from the RO or User to provide these to the Client. A GS may support Registered Clients and/or Dynamic Clients. The GS is a combination of the Authorization Server (AS) in OAuth 2.0, and the OpenID Provider (OP) in OpenID Connect.

- **Resource Server** (RS) - has API resources that require an access token from the GS. Some, or all of the resources are owned by the Resource Owner.

- **Resource Owner** (RO) - owns resources at the RS, and has delegated RS access management to the GS. The RO may be the same entity as the User, or may be a different entity that the GS interacts with independently. GS and RO interactions are out of scope of this document.

## Reused Terms

- **access token** - an access token as defined in {{RFC6749}} Section 1.4.

- **Claim** - a Claim as defined in {{OIDC}} Section 5. Claims may be issued by the GS, or by other issuers. 

- **Client ID** - a GS unique identifier for a Registered Client as defined in {{RFC6749}} Section 2.2.

- **ID Token** - an ID Token as defined in {{OIDC}} Section 2.

- **NumericDate** - a NumericDate as defined in {{RFC7519}} Section 2.

- **authN** - short for authentication.

- **authZ** - short for authorization.

## New Terms

- **GS URI** - the endpoint at the GS the Client calls to create a Grant, and is the unique identifier for the GS.

- **Grant** - the user identity claims and/or RS authorizations the GS has granted to the Client. The GS MAY invalidate a Grant at any time.

- **Grant URI**  - the URI that represents the Grant. The Grant URI MUST start with the GS URI.

- **Authorization** - the access granted by the RO to the Client and contains an access token. The GS may invalidate an Authorization at any time.

- **Authorization URI** (AZ URI) - the URI that represents the Authorization the Client was granted by the RO. The AZ URI MUST start with the GS URI. The AZ URI is used to refresh an access token.

- **Interaction** - how the Client directs the User to interact with the GS. This document defines the interaction modes: "redirect", "indirect", and "user_code" in {{InteractionModes}}

- **Client Handle** - a unique identifier at the GS for a Dynamic Client for the Dynamic Client to refer to itself in subsequent requests.

## Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
specification are to be interpreted as described in {{RFC2119}}.

Certain security-related terms are to be understood in the sense
defined in {{RFC4949}}.  These terms include, but are not limited to,
"attack", "authentication", "authorization", "certificate",
"confidentiality", "credential", "encryption", "identity", "sign",
"signature", "trust", "validate", and "verify".

*\[Editor: review terms]*

Unless otherwise noted, all the protocol parameter names and values
are case sensitive. 

Some protocol parameters are parts of a JSON document, and are referred to in JavaScript notation. For example, foo.bar refers to the "bar" boolean attribute in the "foo" object in the following example JSON document:

    {
        "foo" : {
            "bar": true
        }
    }

# Sequences

Before any sequence, the Client needs to be manually or programmatically configured for the GS. See GS Options {{GSoptions}} for details on programmatically acquiring GS metadata.


## "redirect" Interaction

The Client is a web application and wants a Grant from the User:

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |         +------+
    |        |                                  |       |         | User |
    |        |--(3)--- Interaction Transfer --- | - - - | ------->|      |
    |        |                                  |       |<--(4)-->|      |
    |        |                                  |       |  authN  |      |
    |        |                                  |       |         |      |
    |        |                                  |       |<--(5)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |<--- Interaction Transfer ---(6)- | - - - | --------|      |
    |        |                                  |       |         |      |
    |        |--(7)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |
    |        |<--------- Grant Response ---(8)--|       |
    |        |                                  |       |
    +--------+                                  +-------+
 
1. **Create Grant** The Client creates a Request JSON document {{RequestJSON}} containing an interaction.redirect object and makes a Create Grant request ({{CreateGrant}}) by sending the JSON with an HTTP POST to the GS URI.

2. **Interaction Response**  The GS determines that interaction with the User is required and sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI and an interaction.redirect object.

3. **Interaction Transfer** The Client redirects the User to the authorization_uri at the GS.

4. **User Authentication** The GS authenticates the User.

5. **User Authorization** If required, the GS interacts with the User to determine which identity claims and/or authorizations in the Grant Request are to be granted.

6. **Interaction Transfer** The GS redirects the User to the redirect_uri at the Client. 

7. **Read Grant** The Client makes an HTTP GET request to the Grant URI.

8. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).



## "user_code" Interaction

A Client is on a device wants a Grant from the User:

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |         +------+
    |        |                                  |       |         | User |
    |        |--(3)--- Read Grant ------------->|       |         |      |
    |        |                                  |       |<--(4)-->|      |
    |        |                                  |       |  authN  |      |
    |        |                                  |       |         |      |
    |        |                                  |       |<--(5)---|      |
    |        |                                  |       |  code   |      |
    |        |                                  |       |         |      |
    |        |                                  |       |<--(6)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |                                  |       |         |      |
    |        |<--------- Grant Response ---(7)--|       |         |      |
    |        |                                  |       |         |      |
    +--------+                                  |       |         |      |
                                                |       |         |      |
    +--------+                                  |       |         |      |
    | Client |<----- Completion URI Redirect -- | - - - | --(8)---|      |
    | Server |                                  |       |         |      |
    +--------+                                  +-------+         +------+

1. **Create Grant** The Client creates a Request JSON document {{RequestJSON}} containing an interaction.user_code object and makes a Create Grant request ({{CreateGrant}}) by sending the JSON with an HTTP POST to the GS URI.

2. **Interaction Response**  The GS determines that interaction with the User is required and sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI and an interaction.user_code object.

3. **Read Grant** The Client makes an HTTP GET request to the Grant URI.

4. **User Authentication** The User loads display_uri in their browser, and the GS authenticates the User.

5. **User Code** The User enters the code at the GS.

6. **User Authorization** If required, the GS interacts with the User to determine which identity claims and/or authorizations in the Grant Request are to be granted.

7. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).

8. **Completion URI Redirect** The GS redirects the User to the completion_uri provided by the Client.

## Independent RO Authorization

The Client wants access to resources that require the GS to interact with the RO, who is not interacting with the Client. The authorization from the RO may take some time, so the GS instructs the Client to wait and check back later.

    +--------+                                  +-------+
    | Client |                                  |  GS   |        
    |        |--(1)--- Create Grant ----------->|       |       
    |        |                                  |       |
    |        |<---------- Wait Response ---(2)--|       |         +------+
    |  (3)   |                                  |       |         |  RO  |
    |  Wait  |                                  |       |<--(4)-->|      |
    |        |                                  |       |  AuthZ  |      |
    |        |--(5)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |
    |        |<--------- Grant Response --(6)---|       |
    |        |                                  |       |
    +--------+                                  +-------+

1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) and sends it with an HTTP POST to the GS GS URI.

2. **Wait Response**  The GS sends an Wait Response ({{WaitResponse}}) containing the Grant URI and the "wait" attribute.

3. **Client Waits** The Client waits for the time specified in the "wait" attribute.

4. **RO AuthZ** The GS interacts with the RO to determine which identity claims and/or resource authorizations in the Grant Request are to be granted. 

5. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

6. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).


## Resource Server Access

The Client received an AZ URI from the GS. The Client acquires an access token, calls the RS, and later the access token expires. The Client then gets a fresh access token.


    +--------+                             +----------+  +-------+
    | Client |                             | Resource |  |  GS   |
    |        |--(1)--- Access Resource --->|  Server  |  |       | 
    |        |<------- Resource Response --|   (RS)   |  |       | 
    |        |                             |          |  |       | 
    |        |--(2)--- Access Resource --->|          |  |       | 
    |        |<------- Error Response -----|          |  |       |
    |        |                             |          |  |       | 
    |        |                             +----------+  |       |
    |        |                                           |       |
    |        |--(3)--- Read AuthZ ---------------------->|       |
    |        |<------- AuthZ Response -------------------|       |
    |        |                                           |       |
    +--------+                                           +-------+

1. **Resource Request** The Client accesses the RS with the access token per {{RSAccess}} and receives a response from the RS.

2. **Resource Request** The Client attempts to access the RS, but receives an error indicating the access token needs to be refreshed. 

3. **Read AuthZ** The Client makes a Read AuthZ ({{ReadAuthZ}}) with an HTTP GET to the AZ URI and receives an Response JSON "authorization" object ({{ResponseAuthorizationObject}}) with a fresh access token.



# GS APIs

**Client Authentication**

All GS APIs except for GS Options require the Client to authenticate. Authentication mechanisms include:

+ JOSE Authentication {{JOSE Authentication}}

+ \[Others TBD]*


## GS API Table

| request            | http verb | uri          | response     
|:---                |---        |:---          |:--- 
| GS Options         | OPTIONS   | GS URI       | metadata 
| Create Grant       | POST      | GS URI       | interaction, wait, or grant 
| Read Grant         | GET       | Grant URI    | wait, or grant 
| Read AuthZ         | GET       | AZ URI       | authorization 


## Create Grant {#CreateGrant}

The Client creates a Grant by doing an HTTP POST of a JSON {{RFC8259}} document to the GS URI. This is a Greant Request.

The JSON document MUST include the following from the Request JSON {{RequestJSON}}:

+ iat
+ nonce
+ uri set to the GS URI
+ client

and MAY include the following from Request JSON {{RequestJSON}}

+ user
+ interaction
+ authorization or authorizations
+ claims

The GS MUST respond with one of Grant Response {{GrantResponse}}, Interaction Response {{InteractionResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

Following is a non-normative example of a web application Client requesting identity claims about the User and read access to the User's contacts:

    Example 1

    { 
        "iat"       : 15790460234,
        "uri"       : "https://as.example/endpoint",
        "nonce"     : "f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "client": {
            "display": {
                "name"  : "SPA Display Name",
                "uri"   : "https://spa.example/about"
            }
        },
        "interaction": {
            "redirect": {
                "redirect_uri"    : "https://web.example/return"
            },
            "global" : {
                "ui_locals" : "de"
            }
        },
        "authorization": {
            "type"      : "oauth_scope",
            "scope"     : "read_contacts"
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


Following is a non-normative example of a device Client requesting access to play music using "oauth_rich":

    Example 2

    { 
        "iat"       : 15790460234,
        "uri"       : "https://as.example/endpoint",
        "nonce"     : "5c9360a5-9065-4f7b-a330-5713909e06c6",
        "client": {
            "id"        : "di3872h34dkJW"
        },
        "interaction": {
            "indirect": {
                "completion_uri": "https://device.example/c/indirect"
            },
            "user_code": {
                "completion_uri": "https://device.example/c/user_code"
             }
        },
        "authorization": {
            "type"      : "oauth_rich",
            "scope"     : "play_music",
            "authorization_details" [
                {
                    "type": "customer_information",
                    "locations": [
                        "https://example.com/customers",
                    ]
                    "actions": [
                        "read"
                    ],
                    "datatypes": [
                        "contacts",
                        "photos"
                    ]
                }
            ]
        }
    }

## Read Grant {#ReadGrant}

The Client reads a Grant by doing an HTTP GET of the corresponding Grant URI. The Client MAY read a Grant until it expires or has been invalidated.

The GS MUST respond with one of Grant Response {{GrantResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

+ TBD


## Request JSON {#RequestJSON}

+ **iat** - the time of the request as a NumericDate.

+ **nonce** - a unique identifier for this request. Note the Grant Response MUST contain a matching "nonce" attribute value.

+ **uri** - the GS URI


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

The interaction object contains one or more interaction mode objects per {{InteractionModes}} representing the interactions the Client is willing to provide the User. In addition to the interaction mode objects, the interaction object may contain the "global" object;

+ **global** - an optional object containing parameters that are applicable for all interaction modes. Only one attribute is defined in this document:

    + **ui_locales** - End-User's preferred languages and scripts for the user interface, represented as a space-separated list of {{RFC5646}} language tag values, ordered by preference. This attribute is OPTIONAL.


*\[Editor: ui_locales is taken from OIDC. Why space-separated and not a JSON array?]*


### "user" Object {#RequestUserObject}

+ **identifiers** - The identifiers MAY be used by the GS to improve the User experience. This object contains one or more of the following identifiers for the User:

    + **phone_number** - contains a phone number per Section 5 of {{RFC3966}}.

    + **email** - contains an email address per {{RFC5322}}.

    + **oidc** - is an object containing both the "iss" and "sub" attributes from an OpenID Connect ID Token {{OIDC}} Section 2. 

+ **claims** - an optional object containing one or more assertions the Client has about the User. 

    + **oidc_id_token** - an OpenID Connect ID Token per {{OIDC}} Section 2.

### "authorization" Object {#AuthorizationObject}

+ **type** - one of the following values: "oauth_scope" or "oauth_rich". Extensions MAY define additional types, and the required attributes. This attribute is REQUIRED.

+ **scope** - a string containing the OAuth 2.0 scope per {{RFC6749}} section 3.3. MUST be included if type is "oauth_scope". MAY be included if type is "oauth_rich".  

+ **authorization_details** - an authorization_details JSON array of objects per {{RAR}}. MUST be included if type is "oauth_rich". MUST not be included if type is "oauth_scope"

*\[Editor: details may change as the RAR document evolves]*

### "authorizations" Object 

One or more key / value pairs, where each unique key is created by the client, and the value is an authorization object per {{AuthorizationObject}}.

### "claims" Object {#ClaimsObject}

Includes one or more of the following:

+ **oidc** - an object that contains one or both of the following objects:

    - **userinfo** - Claims that will be returned as a JSON object 

    - **id_token** - Claims that will be included in the returned ID Token. If the null value, an ID Token will be returned containing no additional Claims. 

The contents of the userinfo and id_token objects are Claims as defined in {{OIDC}} Section 5. 

+ **oidc4ia** - OpenID Connect for Identity Assurance claims request per {{OIDC4IA}}.

+ **vc** - *\[Editor: define how W3C Verifiable Credentials {{W3C VC}} can be requested.]*


## Read Authorization {#ReadAuthZ}

The Client acquires and refreshes an Authorization by doing an HTTP GET to the corresponding AZ URI.

The GS MUST respond with a Authorization JSON document {{AuthorizationJSON}}, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

## GS Options {#GSoptions}

The Client can get the metadata for the GS by doing an HTTP OPTIONS of the corresponding GS URI. This is the only API where the GS MAY respond to an unauthenticated request.

The GS MUST respond with the the following JSON document:


+ **uri** - the GS URI.

+ **client_authentication** - a JSON array of the Client Authentication mechanisms supported by the GS

+ **interactions** - a JSON array of the interaction modes supported by the GS.

+ **authorization** - an object containing the authorizations the Client may request from the GS, if any.

    + Details TBD

+ **claims** - an object containing the identity claims the Client may request from the GS, if any, and what public keys the claims will be signed with.

    + Details TBD

+ **algorithms** - a JSON array of the cryptographic algorithms supported by the GS. \[details TBD]*

+ **features** - an object containing feature support

    + **authorizations** - boolean indicating if a request for more than one authorization in a request is supported.

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
+ authorization or authorizations
+ claims
+ expires_in
+ warnings


Example non-normative Grant Response JSON document for Example 1 in {{CreateGrant}}:

    { 
        "iat"           : 15790460234,
        "nonce"         : "f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "uri"           : "https://as.example/endpoint/grant/example1",
        "expires_in"    : 300
        "authorization": {
            "access": {
                "type"  : "oauth_scope",
                "scope" : "read_contacts"
            },
            "expires_in"    : 3600,
            "mechanism"     : "bearer",
            "token"         : "eyJJ2D6.example.access.token.mZf9p"
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

Note in this example the access token can not be refreshed, and expires in an hour.

Example non-normative Grant Response JSON document for Example 2 in {{CreateGrant}}:

    {
        "iat"   : 15790460234,
        "nonce" : "5c9360a5-9065-4f7b-a330-5713909e06c6",
        "uri"   : "https://as.example/endpoint/grant/example2",
        "authorization": {
            "uri"   : "https://as.example/endpoint/authz/example2"
        }
    }

Note in this example the GS only provided the AZ URI, and Client must acquire the Authorization per {{ReadAuthZ}}

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
            ""redirect" : {
                "authorization_uri"     : "https://as.example/i/example4"
            }
        },
        "user": {
            "exists" : true
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

+ **wait** - a numeric value representing the number of seconds the Client should want before making a Read Grant request to the Grant URI.

+ **expires_in** - a numeric value specifying how many seconds until the Grant expires. This attribute is OPTIONAL.

### "client" Object {#clientObject}

The GS may 

### "interaction" Object {#interactionObject}

If the GS wants the Client to start the interaction, the GS MUST return an interaction object containing one or more interaction mode responses per {{InteractionModes}} to one or more of the interaction mode requests provided by the Client. 

### "user" Object

+ **exists** - a boolean value indicating if the GS has a user with one or more of the provided identifiers in the Request user.identifiers object {{RequestUserObject}}


### "authorization" Object {#ResponseAuthorizationObject}

The authorization object MUST contain only a "uri" attribute or the following from Authorization JSON {{AuthorizationJSON}}:

+ mechanism
+ token

The authorization object MAY contain any of the following from Authorization JSON {{AuthorizationJSON}}:

+ access
+ expires_in
+ uri

If there is no "uri" attribute, the access token can not be refreshed. If only the "uri" attribute is present, the Client MUST acquire the Authorization per {{ReadAuthZ}}

### "authorizations" Object {#ResponseAuthorizationsObject}

A key / value pair for each key in the Grant Request "authorizations" object, and the value is per 
{{ResponseAuthorizationObject}}.

### "claims" Object {#ResponseClaimsObject}

The claims object is a response to the Grant Request "claims" object {{AuthorizationObject}}.

+ **oidc**

    - **id_token** - an OpenID Connect ID Token containing the Claims the User consented to be released.
    - **userinfo** - the Claims the User consented to be released.

    Claims are defined in {{OIDC}} Section 5.

+ **oidc4ia** - OpenID Connect for Identity Assurance claims response per {{OIDC4IA}}.

+ **vc**

    The verified claims the user consented to be released. *\[Editor: details TBD]*

### "warnings" JSON Array {#WarningsObject}

Includes zero or more warnings from {{Warnings}},

## Authorization JSON {#AuthorizationJSON}

The Authorization JSON is the contents of a Grant Response "authorization" object {{ResponseAuthorizationsObject}} or the response to a Read AuthZ request by the Client {{ReadAuthZ}}.


+ **type** - the type of claim request: "oauth_scope" or "oauth_rich". See the "type" object in {{AuthorizationObject}} for details.



+ **mechanism** - the RS access mechanism. This document defines the "bearer" mechanism as defined in {{RSAccess}}

+ **token** - the access token for accessing an RS.

+ **expires_in** - a numeric value specifying how many seconds until the access token expires.

+ **uri** - the AZ URI. Used to acquire or refresh an authorization. 

+ **access** - an object containing the access granted:

    + **type** - the type of claim request: "oauth_scope" or "oauth_rich". See the "type" object in {{AuthorizationObject}} for details. This attribute is REQUIRED.

    + **scope** - the scopes the Client was granted authorization for. This will be all, or a subset, of what was requested. This attribute is OPTIONAL.

    + **authorization_details** - the authorization details granted per {{RAR}}. This attribute is OPTIONAL if "type" is "oauth_rich".

*\[Editor: would an optional expiry for the Authorization be useful?]*

The following is a non-normative example of Authorization JSON:

    {
        "mechanism"     : "bearer",
        "token"         : "eyJJ2D6.example.access.token.mZf9p"
        "expires_in"    : 3600,
        "uri"           : "https://as.example/endpoint/authz/example2",
        "access": {
            "type"   : "oauth_scope",
            "scope"  : "read_calendar write_calendar"
        }
    }

## Response Verification

On receipt of a response, the Client MUST verify the following:

+ TBD


# Interaction Modes {#InteractionModes}

This document defines three interaction modes: "redirect", "indirect", and "user_code". Extensions may define additional interaction modes.

The "global" attribute is reserved in the interaction object for attributes that apply to all interaction modes.

## "redirect" 

A Redirect Interaction is characterized by the Client redirecting the User's browser to the GS, the GS interacting with the User, and then GS redirecting the User's browser back to the Client. The GS correlates the Grant Request with the unique authorization_uri, and the Client correlates the Grant Request with the unique redirect_uri.


**The request "interaction" object contains:**

+ **redirect_uri**  a unique URI at the Client that the GS will return the User to. The URI MUST not contain the "nonce" from the Grant Request, and MUST not be guessable. This attribute is REQUIRED.


**The response "interaction" object contains:**

+ **authorization_uri** a unique URI at the GS that the Client will redirect the User to. The URI MUST not contain the "nonce" from the Grant Request, and MUST not be guessable. This attribute is REQUIRED.


## "indirect" 

An Indirect Interaction is characterized by the Client causing the User's browser to load the short_uri at GS, the GS interacting with the User, and then the GS MAY optionally redirect the User's Browser to a completion_uri. There is no mechanism for the GS to redirect the User's browser back to the Client.

 Examples of how the Client may initiate the interaction are encoding the short_uri as a code scannable by the User's mobile device, or launching a system browser from a command line interface (CLI) application.

The "indirect" mode is susceptible to session fixation attacks. See TBD in the Security Considerations for details.

**The request "interaction" object contains:**

+ **completion_uri** an OPTIONAL URI that the GS will redirect the User's browser to after GS interaction.


**The response "interaction" object contains:**

+ **short_uri** the URI the Client will cause to load in the User's browser. The URI SHOULD be short enough to be easily encoded in a scannable code. The URI MUST not contain the "nonce" from the Grant Request, and MUST not be guessable. *\[Editor: recommend a maximum length?]*

## "user_code" 

An Indirect Interaction is characterized by the Client displaying a code and a URI for the User to load in a browser and then enter the code.  *\[Editor: recommend a minimum entropy?]*

**The request "interaction" object contains:**

+ **completion_uri** an OPTIONAL URI that the GS will redirect the User's browser to after GS interaction.


**The response "interaction" object contains:**

+ **code** the code the Client displays to the User to enter at the display_uri. This attribute is REQUIRED.

+ **display_uri** the URI the Client displays to the User to load in a browser to enter the code.


# RS Access {#RSAccess}

The mechanism the Client MUST use to access an RS is in the Authorization JSON "mechanism" attribute {{ResponseAuthorizationObject}}.

The "bearer" mechanism is defined in Section 2.1 of {{RFC6750}}

The "jose" and "jose+body" mechanisms are defined in {{JOSE Authentication}}

A non-normative "bearer" example of the HTTP request headers follows:

    GET /calendar HTTP/2
    Host: calendar.example
    Authorization: bearer eyJJ2D6.example.access.token.mZf9pTSpA


# Error Responses {#ErrorResponses}

+ TBD

# Warnings {#Warnings}

Warnings assist a Client in detecting non-fatal errors.

+ TBD

# Extensibility {#Extensibility}

This standard can be extended in a number of areas:

+ **Client Authentication Mechanisms**

    + An extension could define other mechanisms for the Client to authenticate to the GS and/or RS such as Mutual TLS or HTTP Signing. Constrained environments could use CBOR {{RFC7049}} instead of JSON, and COSE {{RFC8152}} instead of JOSE, and CoAP {{RFC8323}} instead of HTTP/2.

+ **Grant**

    + An extension can define new objects in the Grant Request and Grant Response JSON that return new URIs. 

+ **Top Level**

    + Top level objects SHOULD only be defined to represent functionality other the existing top level objects and attributes.

+ **"client" Object**

    + Additional information about the Client that the GS would require related to an extension.

+ **"user" Object**

    + Additional information about the User that the GS would require related to an extension.

+ **"authorization" Object**

    + Additional authorization schemas in addition to OAuth 2.0 scopes and RAR.

+ **"claims" Object**

    + Additional claim schemas in addition to OpenID Connect claims and Verified Credentials.

+ **interaction modes**

   + Additional types of interactions a Client can start with the User.


+ **Continuous Authentication**

    + An extension could define a mechanism for the Client to regularly provide continuous authentication signals and receive responses.

*\[Editor: do we specify access token introspection in this document, or leave that to an extension?]*


# Rational

1. **Why have both Client ID and Client Handle?**

    While they both refer to a Client in the protocol, the Client ID refers to a pre-registered client,and the Client Handle is specific to an instance of a Dynamic Client. Using separate terms clearly differentiates which identifier is being presented to the GS. 


1. **Why allow Client and GS to negotiate the user interaction mode?**

    The Client knows what interaction modes it is capable of, and the GS knows which interaction modes it will permit for a given Grant Request. The Client can then present the intersection to the User to choose which one is preferred. For example, while a device based Client may be willing to do both "indirect" and "user_code", a GS may not enable "indirect" for concern of a session fixation attack. Additional interaction modes will likely become available which allows new modes to be negotiated between Client and GS as each adds additional interaction modes.

1. **Why have both claims and authorizations?**

    There are use cases for each that are independent: authenticating a user and providing claims vs granting access to a resource. A request for an authorization returns an access token which may have full CRUD capabilities, while a request for a claim returns the claim about the User -- with no create, update or delete capabilities. While the UserInfo endpoint in OIDC may be thought of as a resource, separating the concepts and how they are requested keeps each of them simpler in the Editor's opinion. :)

1. **Why do some of the JSON objects only have one child, such as the identifiers object in the user object in the Grant Request?**

    It is difficult to forecast future use cases. Having more resolution may mean the difference between a simple extension, and a convoluted extension. For example, the "global" object in the "interaction" object allows new global parameters to be added without impacting new interaction modes.


1. **Why is the "iss" included in the "oidc" identifier object? Would the "sub" not be enough for the GS to identify the User?**

    This decouples the GS from the OpenID Provider (OP). The GS identifier is the GS URI, which is the endpoint at the GS. The OP issuer identifier will likely not be the same as the GS URI. The GS may also provide claims from multiple OPs.

1. **Why is there not a UserInfo endpoint as there is with OpenID Connect?**

    Since the Client can Read Grant at any time, it get the same functionality as the UserInfo endpoint, without the Client having to manage a separate access token and refresh token. If the Client would like additional claims, it can Update Grant, and the GS will let the Client know if an interaction is required to get any of the additional claims, which the Client can then start. 
       
    *\[Editor: is there some other reason to have the UserInfo endpoint?]*

1. **Why use URIs for the Grant and Authorization?**
    
    + Grant URI and AZ URI are defined to start with the GS URI, allowing the Client, and GS to determine which GS a Grant or Authorization belongs to.

    + URIs also enable a RESTful interface to the GS functionality.

    + A large scale GS can easily separate out the services that provide functionality as routing of requests can be done at the HTTP layer based on URI and HTTP verb. This allows a separation of concerns, independent deployment, and resiliency.


1. **Why use the OPTIONS verb on the GS URI? Why not use a .well-known mechanism?**

    Having the GS URI endpoint respond to the metadata allows the GS to provide Client specific results using the same Client authentication used for other requests to the GS. It also reduces the risk of a mismatch between the advertised metadata, and the actual metadata. A .well-known discovery mechanism may be defined to resolve from a hostname to the GS URI.



# Acknowledgments

This draft derives many of its concepts from Justin Richer's Transactional Authorization draft {{TxAuth}}. 

Additional thanks to Justin Richer and Annabelle Richard Backman for their strong critique of earlier drafts.

# IANA Considerations

TBD

# Security Considerations

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
- added completion_uri for code flows

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

# Comparison with OAuth 2.0 and OpenID Connect

**Changed Features**

The major changes between GNAP and OAuth 2.0 and OpenID Connect are:

+ The Client always uses a private asymetric key to authenticate to the GS. There is no client secret. i

+ The Client initiates the protocol by making a signed request directly to the GS instead of redirecting the User to the GS.

+ The Client does not pass any parameters in redirecting the User to the GS.

+ The refresh_token has been replaced with a AZ URI that both represents the authorization, and is the URI for obtaining a fresh access token.

+ The Client can request identity claims to be returned independent of the ID Token. There is no UserInfo endpoint to query claims as there is in OpenID Connect.

+ The GS URI is the token endpoint.

**Preserved Features** 

+ GNAP reuses the scopes, Client IDs, and access tokens of OAuth 2.0. 

+ GNAP reuses the Client IDs, Claims and ID Token of OpenID Connect.

+ No change is required by the Client or the RS for accessing existing bearer token protected APIs.

**New Features**

+ All Client calls to the GS are authenticated with asymetric cryptography

+ A Grant represents both the user identity claims and RS access granted to the Client.

+ Support for scannable code initiated interactions.

+ Highly extensible per {{Extensibility}}.
