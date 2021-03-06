//
//  DownloadManager.swift
//  Flycatcher
//
//  Created by Enrico Franzelli on 06/04/16.
//  Copyright © 2016 Capibara. All rights reserved.
//

import Foundation

protocol FlycatcherDownloadManager {
  var baseURL: NSURL { get set }
  var concurrencyLevel: Int { get set }
  
  func load(url: NSURL, options: Set<ResourceDownloadOptions>, progress: ((DownloadProgress) -> Void)?, completion: ((FlycatcherResult) -> Void)?)
  func preload(urls: [String])
}

public class DownloadManager: FlycatcherDownloadManager {
  let defaultResourceDownloadOptions: Set<ResourceDownloadOptions> = []
  var successor: FlycatcherRequestHandler = Cacher()
  
  /// The base URL to use when loading resource
  public var baseURL = NSURL()
  public var baseURLString: String {
    var string = baseURL.absoluteString
    
    if string.characters.count > 0 && string.characters.last != "/" {
      string = string + "/"
    }
    
    return string
  }
  
  /// Specify how many download are simultaneously executing while
  /// downloading resources.
  public var concurrencyLevel: Int = 2 {
    didSet(newValue) {
      if newValue > 8 {
        print("Concurrency level cannot be great than 8. Setting it to 8.")
        concurrencyLevel = 8
      }
      
      if newValue < 1 {
        print("Concurrency level cannot be lower than 1. Setting it to 1.")
        concurrencyLevel = 1
      }
    }
  }
  
  public func load(url: String, completion: ((FlycatcherResult) -> Void)?) {
    let nsurl = NSURL(string: checkBaseURL(url))
    
    if let correctURL = nsurl {
      self.load(correctURL, completion: completion)
    }
    else {
      print("The URL \(url) was malformed, cannot load it")
    }
  }
  
  public func load(url: NSURL, completion: ((FlycatcherResult) -> Void)?) {
    self.load(url, options: defaultResourceDownloadOptions, progress: nil, completion: completion)
  }
  
  public func load(url: String, options: Set<ResourceDownloadOptions> = [], progress: ((DownloadProgress) -> ())?, completion: ((FlycatcherResult) -> ())?) {
    let nsurl = NSURL(string: checkBaseURL(url))
    
    if let correctURL = nsurl {
      self.load(correctURL, options: options, progress: progress, completion: completion)
    }
    else {
      print("The URL \(url) was malformed, cannot load it")
    }
  }
  
  public func load(url: NSURL, options: Set<ResourceDownloadOptions>, progress: ((DownloadProgress) -> ())?, completion: ((FlycatcherResult) -> Void)?) {
    // CONSTRUCT REQUEST
    // Resource
    var resource = FlycatcherResource(url: url)
    
    // Disable URL normalize
    if options.contains(.PreciseURL) {
      resource.normalizedURL = url
    }
    else {
      resource.normalizedURL = url.normalizedURL
    }
    
    var request = FlycatcherRequest(
      partialResult: .Success(resource),
      progress: progress,
      completion: completion
    )
    
    // Disable cell data if needed
    if options.contains(.DisableCellularData) {
      request.cellularDataAllowed = false
    }
    
    // Download timeout
    if options.contains(.DownloadTimeout(0)) {
      let timeoutSet: Set<ResourceDownloadOptions> = [.DownloadTimeout(0)]
      let timeout = options.intersect(timeoutSet).first!
      
      switch timeout {
      case .DownloadTimeout(let timeout):
        request.downloadTimeout = timeout
      default: break
      }
    }
    
    // Pass to successor
    successor.handle(request)
  }
  
  public func preload(urls: [NSURL]) {
    urls.forEach { (url) in
      load(url, completion: nil)
    }
  }
  
  public func preload(urls: [String]) {
    let nsUrls = urls.flatMap { (stringURL) -> NSURL? in
      if let url = NSURL(string: checkBaseURL(stringURL)) {
        return url
      }
      return nil
    }
    
    preload(nsUrls)
  }
}

extension DownloadManager {
  private func checkBaseURL(url: String) -> String {
    var urlToCheck = url
    
    if urlToCheck.containsString(self.baseURLString) {
      urlToCheck = urlToCheck.stringByReplacingOccurrencesOfString(baseURLString, withString: "")
    }
    
    return baseURLString + urlToCheck
  }
}

extension DownloadManager: FlycatcherRequestHandler {
  func nextSuccessor() -> FlycatcherRequestHandler? {
    return nil
  }
  
  func handle(request: FlycatcherRequest) {
    
  }
}