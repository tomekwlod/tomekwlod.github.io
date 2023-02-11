window.log = (function () {
      try {
        return console.log;
      } catch (e) {
        return function () {};
      }
    })();
    
    window.env = (function (e) {
      return function (key, def) {
        if (typeof key === "undefined") {
          return Object.assign({}, e);
        }
    
        if (typeof key !== "string") {
          throw new Error(
            "preprocessed.js window.env() error: key is not a string"
          );
        }
    
        if (!key.trim()) {
          throw new Error(
            "preprocessed.js window.env() error: key is an empty string"
          );
        }
    
        var val = e[key];
    
        if (typeof val === "undefined") {
          return def;
        }
    
        return val;
      };
    })({
      PROJECT_NAME: "tomekwlod",
  NODE_PORT: "7898",
  GITHUB_SOURCES_PREFIX: "https://github.com/tomekwlod/tomekwlod.github.io",
    });
    
    log("const env = window.env");
    