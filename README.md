Asthma Health
=============
The Asthma Health app, among the first apps to make use of Apple's ResearchKit, allows researchers to leverage the power of smartphones to conduct far-ranging studies of asthma for relatively low cost.  Upon downloading the app, users can consent to the Asthma Mobile Health Study, securely transmit data about their past medical history and ongoing symptoms. Users can also learn about asthma and local air quality, review trends in their activity and other variables, and receive personalized reminders to prescribed medications. 

More about this app is available at: http://icahndigitalhealth.org/asthmastudy/


Building the App
================
### Requirements:
- Xcode version 7.3.1
- iOS Deployment Target: 9.3
- Build Settings (Code Signing Identity, Provisioning Profile)

#### Certificates
All confidential data have been removed and proper places have been marked.

Precisely:

##### Sage Bridge API Certificates:

 - Asthma/Resources/Certificates/asthma.pem
 - Asthma/Resources/Certificates/asthma-staging.pem
 - Asthma/Resources/Certificates/mssm_asthma_public_04092015.pem 

##### API keys and others (stored in plist files*):
 - 23andMe: 23andmeClientId, 23andmeSecret, 23andmeUrl.
- AWS: AWSAppID, CognitoID
- Crashlytics: Fabric/APIKey.

* there are 2 Info.plist files: one for Asthma target (Info.plist) and one for Asthma QA target (Asthma QA.plist).

They were marked by "<REPLACE-ME>”.
The application without this could be build and run on the device, but it won’t work properly.

### Getting the source

First, check out the source, including all the dependencies:

```
git clone -b ms-asthma-1.5 https://github.com/lifemap-solutions/AsthmaHealth
```

### Building it

Open the project, `Asthma.xcodeproj`, and build and run.


Other components
================

The [EuroQoL EQ-5D](http://www.euroqol.org/about-eq-5d.html) survey instrument
is used in the shipping app, but has been removed from the open source
version because it is not free to use.

The shipping app also uses OpenSSL to add extra data protection, which
has not been included in the published version of the AppCore
project. See the [AppCore repository](https://github.com/researchkit/AppCore) for more details.

Data upload to [Bridge](http://sagebase.org/bridge/) has been disabled, the logos of the institutions have been removed, and the consent material has been marked as an example.

License
=======

The source in the AsthmaHealth repository is made available under the
following license unless another license is explicitly identified:

```
Copyright (c) 2015, Icahn School of Medicine at Mount Sinai. All rights reserved. 

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributors
may be used to endorse or promote products derived from this software without
specific prior written permission. No license is granted to the trademarks of
the copyright holders even if such marks are included in this software.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

