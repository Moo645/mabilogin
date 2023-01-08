require 'openssl'

class TestCipher
  def initialize(**data_set)
    @key = data_set[:key]
    @data = [data_set[:data]].pack('H*')
    @cipher = OpenSSL::Cipher.new('des-ecb')
  end

  def info
    puts '------------------------------------------------------------'
    puts "| key: #{@key}, ", "| data: #{unpack_it(@data)}"
    puts '------------------------------------------------------------'
  end
  
  def encrypt_data
    puts 'ENCRYPT:'
    @cipher.encrypt
    @cipher.key = @key
    @cipher.padding = 0
    data = @cipher.update @data
    data << @cipher.final
    @data = data
    puts "encrypt_data: #{unpack_it(data)} / #{data.encoding}"
    puts '------------------------------------------------------------'
  end
  
  def decrypt_data
    puts 'DECRYPT:'
    @cipher.decrypt
    @cipher.key = @key
    @cipher.padding = 0
    data = @cipher.update(@data)
    data << @cipher.final
    @data = data
    puts "decrypt_data: #{@data} / #{data.encoding}"
    puts '------------------------------------------------------------'
  end
end

def unpack_it(str)
  str.unpack1('H*').upcase
end

def test
  cipher = 'des-ecb'
  data_set = {
    h: {
      key: '614A9ECB',
      data: 'FB95D5E5A8E0C50679E8A65A7C3EFCE0'
    },

    a: {
      key: 'B7828DEB',
      data: 'E27AADFEC3FCCFC0A81E82A01755A542'
    },

    b: {
      key: '50622632',
      data: 'DDD21A0C994DED52099A719586C95F9C'
    }
  }

  cipher = TestCipher.new(**data_set[:h])
  cipher.info
  cipher.decrypt_data
  cipher.encrypt_data
  cipher.decrypt_data
end

test if __FILE__ == $0
