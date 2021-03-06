require 'test/unit'
require File.dirname(__FILE__) + '/../lib/tlv'

class TestDGI < Test::Unit::TestCase
	include TLV
  def setup
  end
  
  class TLVTest < DGI
    tlv "0101", "Test TLV"
    b   8,   "first field",  :first
    b   8,   "second field", :second
  end

  class TLVTest2 < DGI
    tlv "0102", "Test Rubify"
    b   8,   "My Test"
    b   8,   "Oh M@i!"
  end

  class TLVTest3 < DGI
    tlv "9F00", "Test Raw"
    raw
  end
  class TLVTestNoTag < DGI
    b   8,   "first field",  :first
    b   8,   "second field", :second
  end

  def basics tlv
    tlv.first="\x01"
    tlv.second="\xAA"
    assert_equal "\x01", tlv.first
    assert_equal "\xaa", tlv.second

    assert_raise(RuntimeError) {
      tlv.first="\x02\x03"
    }
    assert_raise(RuntimeError) {
      tlv.first=Time.new
    }
    assert_raise(RuntimeError) {
      tlv.second=1
    }
  end

  def test_basics
    t = TLVTest.new
    basics t
    assert_equal "\x01\x01\x02\x01\xaa", t.to_b

  end 

  def test_parse_tag

  end

  def test_length
    t = TLVTest3.new
    t.value = ""
    assert_equal "\x00", t.to_b[2,1]
    t.value = "1"
    assert_equal "\x01\x31", t.to_b[2,2]
    t.value = "1"*127
    assert_equal "\x7F\x31", t.to_b[2,2]
    t.value = "1"*128
    assert_equal "\x80\x31", t.to_b[2,2]
    t.value = "1"*255
    assert_equal "\xFf\x00\xff\x31", t.to_b[2,4]
    t.value = "1"*256
    assert_equal "\xFF\x01\x00\x31", t.to_b[2,4]
    
    assert_raises (RuntimeError) {
      t.value = "1"*65535
      assert_equal "\x82\xFF\xFF\x31", t.to_b[2,4]
    }
    
    o = Object.new
    def o.length
      return 4294967296
    end
    
    assert_raises (RuntimeError) {
      t.value=o
      t.to_b
    }
  end

  def test_parse
    t = TLVTest.new
    assert_equal "\x00", t.first
    t.first="\x01"
    t.second="\xAA"
    
    assert "\x01", t.first
    bytes = t.to_b
#    t, rest = TLVTest.parse bytes
#    assert_equal TLVTest, t.class
#    assert_equal "\x01", t.first
#    assert_equal "\xAA", t.second
  end
  def test_rubify
    t = TLVTest2.new
    t.my_test = "\x01"
    assert_equal "\x01", t.my_test
    t.oh_mi = "\x02"
    assert_equal "\x02", t.oh_mi
  end
  def test_raw
    t = TLVTest3.new
    #puts t.methods.sort
    t.value= "bumsi"
    assert_equal "Test Raw", TLVTest3.display_name
    assert_equal "bumsi", t.value
    bytes =  t.to_b
#    t, rest = TLVTest3.parse bytes
#    assert_equal "bumsi", t.value
#    assert_equal TLVTest3, t.class
  end


end
