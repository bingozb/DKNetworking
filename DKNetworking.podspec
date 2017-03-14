Pod::Spec.new do |s|
    s.name         = "DKNetworking"
    s.version      = "v0.0.1"
    s.ios.deployment_target = '8.0'
    s.summary      = "基于 AFNetworking + YYCache + MJExtension 封装的可持久化网络层框架"
    s.homepage     = "https://github.com/bingozb/DKNetworking"
    s.license              = { :type => "MIT", :file => "LICENSE" }
    s.author             = { "bingozb" => "454113692@qq.com" }
    s.source       = { :git => "https://github.com/bingozb/DKNetworking.git", :tag => "v0.0.1" }
    s.source_files  = "DKNetworking/*.{h,m}"
    s.requires_arc = true
    s.libraries         = 'libsqlite3.0'
    s.dependency 'AFNetworking', 'MJExtension', 'YYCache'
end