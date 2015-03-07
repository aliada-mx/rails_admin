// Bluebird custom exceptions
EmailAlreadyExists = function(error){
  this.message = error.message;
  this.name = "EmailAlreadyExists";
  Error.captureStackTrace(this, EmailAlreadyExists);
};
EmailAlreadyExists.prototype = Object.create(Error.prototype);
EmailAlreadyExists.prototype.constructor = EmailAlreadyExists;

PostalCodeMissing = function(error){
  this.message = error.message;
  this.name = "PostalCodeMissing";
  Error.captureStackTrace(this, PostalCodeMissing);
};
PostalCodeMissing.prototype = Object.create(Error.prototype);
PostalCodeMissing.prototype.constructor = PostalCodeMissing;

ConektaFailed = function(message){
  this.message = message
  this.name = "ConektaError";
  Error.captureStackTrace(this, ConektaFailed);
};
ConektaFailed.prototype = Object.create(Error.prototype);
ConektaFailed.prototype.constructor = ConektaFailed;

ServiceCreationFailed = function(error){
  this.message = error.message;
  this.name = "ServiceCreationFailed";
  Error.captureStackTrace(this, ServiceCreationFailed);
};
ServiceCreationFailed.prototype = Object.create(Error.prototype);
ServiceCreationFailed.prototype.constructor = ServiceCreationFailed;

PlatformError = function(error){
  this.message = error.message;
  this.name = "PlatformError";
  Error.captureStackTrace(this, ServiceCreationFailed);
};
PlatformError.prototype = Object.create(Error.prototype);
PlatformError.prototype.constructor = PlatformError;
