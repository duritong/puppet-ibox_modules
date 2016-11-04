require 'spec_helper'
require 'fileutils'

describe 'get_services_to_balance' do
  before(:all) do
    @tmp_path = File.expand_path(File.join(File.dirname(__FILE__),'..','fixtures','tmp'))
    @test_path = File.join(@tmp_path,'test.key')
    @mx5guxonqb5cttqg_str = "-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCvdfyn0O4nSQgnmX3CmuWGjxE0BkjibYghRif+nqoaovHHYS2M
23Ycvglw0wJjyJV9Zjl2QrUbKGuAb1S/+qWYppQhNrnLO5PeVLhWlk0KxSg+/NCr
xYie7jF7dXG+xcY6co6oFjCkm9CiWeiPS98ZkiYhXKgn87TkyLjzDIROnwIDAQAB
AoGAJ+hUEO9KW5EW07rriamlbtd3eDe9uBJllfvY+OapleldyJVnwNPhp2PpzcmQ
j5V9usnXY/iELKsi2FF6GzgtFYvY6sAzwwxxW7+6LyRNaXR9+wu9x/GK/btmNFcp
ex2gthmCbANB/ZF70/V9sjUlrXN3p+BEdJ5JYBZ281K9qKECQQC3vkjoS+IRvhI3
Zue1yWx079YxCJ7aFd8mfImU9F43xz9RUCKkQ680FN4FRj6KXj6ZQGsItZp20W2G
ZC+1fRlZAkEA9HXmKfoIEtlU+ZjCnEnQXGOyTohFQ1SI6zCjeFBFz/uNASdYHEKc
G6CbVICotUb3vJi2xpjsCWig/tF8hLqwtwJAONjSTaxMgRjBIgrgXUm4GGWravgz
zV0+8PVOy5rfG3q1iD62uQOHzSE3n4IgD0chLuDTPJqS83fP3uhYKlpN4QJBAND8
td7u9NYAXEfhU4Y/CFTjmjzO/L+Z1k+STj3+CiDLAXmaBBZsz35C6Gfuccw/tmzR
9XeEpk1I2FHgD159J7MCQDFP0WGZEDZqHmS3CNeIHBNkjAk4bbt7KLfmQWCEVcf1
zA13Igk0SxJW0HKqEdtVI4ceTygKOHpla9RBMOQGSn0=
-----END RSA PRIVATE KEY-----\n"
    @drpsyff5srkctr7h_str = "-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQC9OUBOkL73n43ogC/Jma54/ZZDEpoisqpkGJHgbcRGJIxcqqfL
PbnT3hD5SUCVXxLnzWDCTwTe2VOzIUlBXmslwVXnCJh/XGZg9NHiNU3EAZTwu1g9
8gNmmG1bymaoEBkuC1osijOj+CN+gzLzApiMbDxddpxTn70LWaSqMDbfdQIDAQAB
An88nBn9EGAa8QCDeIvWB2PbXV7EHTFB6/ioFzairIYx8YMEK6WTdDIRqw/EybHm
Jo3nseFMXAMzXmlw9zh/t76ZzE7ooYocSPIEzpu4gDRsa5/mqRCGajs8A8ooiHN5
Tc9cHzIfhjOYhu3VxF0G9LTAC8nKdWQkHm+h+J6A6+wBAkEA2E6GcIdPGTSfaNRS
BHOpKUUSvH7W0e5fyYe221EhESdTFjVkaO5YN9HvcqYh27nik0azKgNj6PiE01FC
0q4fgQJBAN/ycGS3dX5WRXEOpbQ04LKyxCFMVgS+tN5ueDgbv/SxWAxidLYcVfbg
CcUA+L2OaQ95S97CxYlCLda10vIPOfUCQQCUvQJzFIgOlAHdqsovJ3011Lp6hVmg
h6K0SK8zhkkPq5PVnKdMBEEDOUfG9XgoyFyF20LN7ADirSlgyesCRhuBAkEAmuCE
MmNecn0fkUzb9IENVQik85JjeuyZEau8oLEwU/3CMu50YO2/1fijSQee/xlaN0Vf
3zM8geyu3urodFdrcQJBAMBcecMvo4ddZ/GnwpKJuXEhKSwQfPOeb8lK12NvKuVE
znq+qT/KbJlwy/27X/auCAzD5rJ9VVzyWiu8nnwICS8=
-----END RSA PRIVATE KEY-----\n"
  end
  describe 'signature validation' do
    it { is_expected.not_to eq(nil) }
    it { is_expected.to run.with_params().and_raise_error(Puppet::ParseError, /Takes a path/) }
    it { is_expected.to run.with_params(1).and_raise_error(Puppet::ParseError, /Takes a path/) }
    it { is_expected.to run.with_params('/tmp','test').and_raise_error(Puppet::ParseError, /Takes a path/) }
    it { is_expected.to run.with_params('/etc/passwd',['test']).and_raise_error(Puppet::ParseError, /Path \/etc\/passwd must be a directory/) }
  end

  describe 'normal operation' do
    before(:all) do
      FileUtils.rm_rf(@tmp_path) if File.exists?(@tmp_path)
      FileUtils.mkdir_p(@tmp_path)
      File.open(File.join(@tmp_path,'test.key'),'w'){|f| f << @drpsyff5srkctr7h_str }
      File.open(File.join(@tmp_path,'test_1.key'),'w'){|f| f << @drpsyff5srkctr7h_str }
      File.open(File.join(@tmp_path,'test_2.key'),'w'){|f| f << @drpsyff5srkctr7h_str }
      File.open(File.join(@tmp_path,'test_3.key'),'w'){|f| f << @drpsyff5srkctr7h_str }
      File.open(File.join(@tmp_path,'foo.key'),'w'){|f| f << @mx5guxonqb5cttqg_str }
      File.open(File.join(@tmp_path,'foo_1.key'),'w'){|f| f << @mx5guxonqb5cttqg_str }
      File.open(File.join(@tmp_path,'bar_1.key'),'w'){|f| f << @mx5guxonqb5cttqg_str }
    end
    after(:all) do
      FileUtils.rm_rf(@tmp_path) if File.exists?(@tmp_path)
    end
    context 'without an existing key' do
      it { is_expected.to run.with_params(@tmp_path,['test','foo']).and_return(
        {
          'drpsyff5srkctr7h' => {
            'test_1'       => 'drpsyff5srkctr7h',
            'test_2'       => 'drpsyff5srkctr7h',
            'test_3'       => 'drpsyff5srkctr7h',
            '_key_content' => @drpsyff5srkctr7h_str,
          },
          'mx5guxonqb5cttqg' => {
            'foo_1' => 'mx5guxonqb5cttqg',
            '_key_content' => @mx5guxonqb5cttqg_str,
          }
        }
      ) }
    end
  end
end
