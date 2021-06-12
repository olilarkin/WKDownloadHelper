//
//  WKDownloadHelper+delegate.swift
//  WKDownloadHelper
//
//  Created by Gualtiero Frigerio on 12/06/21.
//  Copyright © 2021 Gualtiero Frigerio. All rights reserved.
//

import Foundation
import WebKit

@available(iOS 11.0, *)
extension WKDownloadHelper: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let delegate = delegate,
           let url = navigationAction.request.url {
            let allow = delegate.canNavigate(toUrl: url)
            if allow {
                decisionHandler(.allow)
            }
            else {
                decisionHandler(.cancel)
            }
        }
        else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let url = navigationResponse.response.url else {
            decisionHandler(.cancel)
            return
        }
        if let delegate = delegate {
            let canNavigate = delegate.canNavigate(toUrl: url)
            if canNavigate == false {
                decisionHandler(.cancel)
                return
            }
        }
        if let mimeType = navigationResponse.response.mimeType {
            if isMimeTypeConfigured(mimeType) {
                if #available(iOS 14.5, *) {
                    decisionHandler(.download)
                } else {
                    var fileName = getDefaultFileName(forMimeType: mimeType)
                    if let name = getFileNameFromResponse(navigationResponse.response) {
                        fileName = name
                    }
                    downloadData(fromURL: url, fileName: fileName) { success, destinationURL in
                        if success,
                           let destinationURL = destinationURL,
                           let delegate = self.delegate {
                            delegate.didDownloadFile(atUrl: destinationURL)
                        }
                    }
                    decisionHandler(.cancel)
                }
                return
            }
        }
        decisionHandler(.allow)
    }
    
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
}

@available(iOS 14.5, *)
extension WKDownloadHelper: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let temporaryDir = NSTemporaryDirectory()
        let fileName = temporaryDir + "/" + suggestedFilename
        let url = URL(fileURLWithPath: fileName)
        fileDestinationURL = url
        completionHandler(url)
    }
    
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        delegate?.didFailDownloadingFile(error: error)
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        if let url = fileDestinationURL,
           let delegate = self.delegate {
            delegate.didDownloadFile(atUrl: url)
        }
    }
}