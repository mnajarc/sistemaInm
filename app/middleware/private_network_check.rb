# app/middleware/private_network_check.rb
class PrivateNetworkCheck
  PRIVATE_RANGES = [
    IPAddr.new('127.0.0.1/8'),
    IPAddr.new('10.0.0.0/8'),
    IPAddr.new('172.16.0.0/12'),
    IPAddr.new('192.168.0.0/16')
  ]

  def initialize(app)
    @app = app
  end

  def call(env)
    path = env['PATH_INFO']
    
    # Rutas que requieren red privada
    if path.start_with?('/admin/instance-settings')
      ip = IPAddr.new(env['REMOTE_ADDR'])
      
      unless PRIVATE_RANGES.any? { |range| range.include?(ip) }
        return [403, {}, ["Acceso denegado"]]
      end
    end
    
    @app.call(env)
  end
end

# config/application.rb
config.middleware.insert_before 0, PrivateNetworkCheck
