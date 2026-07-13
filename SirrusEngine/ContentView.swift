//
//  ContentView.swift
//  SirrusEngine
//
//  Created by aslan on 13.07.2026.
//

import SwiftUI
import WebKit

// MARK: - ANA GÖRÜNÜM
struct ContentView: View {
    @State private var ip: String = "192.168.0.29"
    @State private var port: String = "4001"
    @State private var showWebView = false
    @State private var isLoading = false
    @State private var errorMessage: String = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Sirrus Engine")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("iOS WebView Bağlantı")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IP Adresi")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Örn: 192.168.0.29", text: $ip)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Port Numarası")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Örn: 4001", text: $port)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .font(.body)
                    }
                }
                .padding(.horizontal, 30)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                Button(action: {
                    connect()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "link")
                            Text("Bağlan")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
                }
                .padding(.horizontal, 30)
                .disabled(isLoading)
                
                Spacer()
                
                Text("v1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showWebView) {
            SimpleWebView(
                ip: ip,
                port: port,
                onDisconnect: {
                    showWebView = false
                    isLoading = false
                }
            )
        }
    }
    
    func connect() {
        guard !ip.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Lütfen IP adresini girin"
            showError = true
            return
        }
        
        guard !port.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Lütfen port numarasını girin"
            showError = true
            return
        }
        
        guard let _ = Int(port) else {
            errorMessage = "Port numarası geçerli bir sayı olmalı"
            showError = true
            return
        }
        
        showError = false
        errorMessage = ""
        isLoading = true
        showWebView = true
        isLoading = false
    }
}

// MARK: - BASİT WEBVIEW
struct SimpleWebView: View {
    let ip: String
    let port: String
    let onDisconnect: () -> Void
    
    @State private var isLoading = true
    @State private var pageTitle: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // WebView
                SimpleWebViewContainer(
                    urlString: "http://\(ip):\(port)/index.html",
                    isLoading: $isLoading,
                    pageTitle: $pageTitle
                )
                .edgesIgnoringSafeArea(.all)
                
                // Yükleme Göstergesi
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                        Text("Yükleniyor...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
            .navigationTitle(pageTitle.isEmpty ? "\(ip):\(port)" : pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        onDisconnect()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - BASİT WEBVIEW CONTAINER
struct SimpleWebViewContainer: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // URL'yi yükle
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SimpleWebViewContainer
        
        init(_ parent: SimpleWebViewContainer) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                
                // Sayfa başlığını al
                webView.evaluateJavaScript("document.title") { result, error in
                    if let title = result as? String, !title.isEmpty {
                        self.parent.pageTitle = title
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.pageTitle = "Hata"
                print("❌ Yükleme hatası: \(error.localizedDescription)")
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.pageTitle = "Hata"
                print("❌ Bağlantı hatası: \(error.localizedDescription)")
            }
        }
    }
}

