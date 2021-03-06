require 'test/unit'
require File.dirname(__FILE__) + '/../lib/tlv'

class TestTLV < Test::Unit::TestCase
	include TLV

  def setup
  end
  
  class TLVTest < TLV
    tlv "11", "Test TLV"
    b   8,   "first field",  :first
    b   8,   "second field", :second
  end

  class TLVTest2 < TLV
    tlv "42", "Test Rubify"
    b   8,   "My Test"
    b   8,   "Oh M@i!"
  end

  class TLVTest3 < TLV
    tlv "9F7F", "Test Raw"
    raw
  end
  class TLVTest4 < TLV
    tlv 0x9F71, "Test Fixnum"
    raw
  end
  class DGITest4 < DGI
    tlv 0x0101, "Test Fixnum"
    raw
  end

  class TLVTest5 < TLV
    tlv 0x70, "Test Fixnum 2"
    raw
  end
  class TLVTestNoTag < TLV
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
    assert_equal "\x11\x02\x01\xaa", t.to_b
    assert_equal "\x01\xaa", t.get_bytes

    t = TLVTestNoTag.new
    basics t
    assert_equal "\x01\xaa", t.to_b
    assert_equal t.to_b, t.get_bytes
  end 

  def test_parse_tag
    bytes = "\x01\x00\x00"
    tag, rest = TLV.get_tag bytes
    assert_equal "\x01", tag
    assert_equal "\x00\x00", rest

    bytes = "\xFF\x00\x00"
    tag, rest = TLV.get_tag bytes
    assert_equal "\xff\x00", tag
    assert_equal "\x00", rest


    bytes = "\xFF\x85\xAA"
    tag, rest = TLV.get_tag bytes
    assert_equal "\xff\x85\xaa", tag
    assert_equal "", rest
    
    bytes = "\x11\x02\x01\xaa"
    tag, rest = TLV.get_tag bytes
    assert_equal "\x11", tag
    assert_equal "\x02\x01\xaa", rest


    bytes = TLV.s2b "9f7f2aff"
    tag, rest = TLV.get_tag bytes
    assert_equal "\x9f\x7f", tag
    assert_equal "\x2a\xff", rest

    length, rest = TLV.get_length rest
    assert_equal 0x2a, length


  end
  def test_parse_length
    bytes = "\x03\x02"
    len, rest = TLV.get_length bytes
    assert_equal 3, len
    assert_equal "\x02", rest
    
    bytes = "\x81\x02\x11\x22"
    len, rest = TLV.get_length bytes
    assert_equal 2, len
    assert_equal "\x11\x22", rest


    bytes = "\x84\x00\x00\x00\x02\x11\x22"
    len, rest = TLV.get_length bytes
    assert_equal 2, len
    assert_equal "\x11\x22", rest


    bytes = "\x83\x00\x00\x02\x11\x22"
    len, rest = TLV.get_length bytes
    assert_equal 2, len
    assert_equal "\x11\x22", rest
    
    bytes = "\x82\x10\x01\x11\x22"
    len, rest = TLV.get_length bytes
    assert_equal 4097, len
    assert_equal "\x11\x22", rest
    
    bytes = "\x83\x00\x10\x01\x11\x22"
    len, rest = TLV.get_length bytes
    assert_equal 4097, len
    assert_equal "\x11\x22", rest
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
    assert_equal "\x81\x80\x31", t.to_b[2,3]
    t.value = "1"*255
    assert_equal "\x81\xFF\x31", t.to_b[2,3]
    t.value = "1"*256
    assert_equal "\x82\x01\x00\x31", t.to_b[2,4]
    t.value = "1"*65535
    assert_equal "\x82\xFF\xFF\x31", t.to_b[2,4]
    t.value = "1"*65536
    assert_equal "\x84\x00\x01\x00\x00\x31", t.to_b[2,6]
    
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
    t, rest = TLV.parse bytes
    assert_equal TLVTest, t.class
    assert_equal "\x01", t.first
    assert_equal "\xAA", t.second
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
    t, rest = TLV.parse bytes
    assert_equal "bumsi", t.value
    assert_equal TLVTest3, t.class
  end

  def test_fixnum
    t = TLVTest4.new
    t.value = "123"
    assert_equal(TLV.s2b("9f7103313233"), t.to_b)

    t2 = TLVTest5.new
    t2.value = "321"
    assert_equal(TLV.s2b("7003333231"), t2.to_b)

    d = DGITest4.new
    assert_equal("\x01\x01", d.tag)
  end



end
