require 'spec_helper'

RSpec.describe ActiveSupport::Cache::DatabaseStore do
  subject do
    described_class.new expires_in: 60
  end

  it 'should read and write strings' do
    expect(subject.write('foo', 'bar')).to be_truthy
    expect(subject.read('foo')).to eq('bar')
  end

  it 'should read and write hash' do
    expect(subject.write('foo', a: 'b')).to be_truthy
    expect(subject.read('foo')).to eq(a: 'b')
  end

  it 'should read and write integer' do
    expect(subject.write('foo', 1)).to be_truthy
    expect(subject.read('foo')).to eq(1)
  end

  it 'should read and write nil' do
    expect(subject.write('foo', nil)).to be_truthy
    expect(subject.read('foo')).to eq(nil)
  end

  it 'should read and write false' do
    expect(subject.write('foo', false)).to be_truthy
    expect(subject.read('foo')).to eq(false)
  end

  it 'should overwrite' do
    expect(subject.write('foo', 'bar')).to be_truthy
    expect(subject.write('foo', 'baz')).to be_truthy
    expect(subject.read('foo')).to eq('baz')
  end

  it 'should support exist?' do
    subject.write('foo', 'bar')
    expect(subject.exist?('foo')).to be_truthy
    expect(subject.exist?('bar')).to be_falsey
  end

  it 'should support nil exist?' do
    subject.write('foo', nil)
    expect(subject.exist?('foo')).to be_truthy
  end

  it 'should support delete' do
    subject.write('foo', 'bar')
    expect(subject.exist?('foo')).to be_truthy
    expect(subject.delete('foo')).to be_truthy
    expect(subject.exist?('foo')).to be_falsey
  end

  it 'should support expires_in' do
    time = Time.local(2008, 4, 24)
    allow(Time).to receive(:now).and_return(time)

    subject.write('foo', 'bar')
    expect(subject.read('foo')).to eq('bar')

    allow(Time).to receive(:now).and_return(time + 30)
    expect(subject.read('foo')).to eq('bar')

    allow(Time).to receive(:now).and_return(time + 61)
    expect(subject.read('foo')).to be_nil
  end

  it 'should support long keys' do
    key = 'x' * 255
    expect(subject.write(key, 'bar')).to be_truthy
    expect(subject.read(key)).to eq('bar')
    expect(subject.fetch(key)).to eq('bar')
    expect(subject.read(key[0..-2])).to be_nil
    expect(subject.read_multi(key)).to eq(key => 'bar')
    expect(subject.delete(key)).to be_truthy

    expect { subject.write("#{key}x", 'bar') }.to raise_error(ArgumentError, /exceeds the length limit/)
    expect { subject.read("#{key}x") }.to raise_error(ArgumentError, /exceeds the length limit/)
  end

  describe '#cleanup' do
    it 'should delete expired' do
      time = Time.now
      subject.write('foo', 'bar', expires_in: 10)
      subject.write('fud', 'biz', expires_in: 20)

      allow(Time).to receive(:now).and_return(time + 9)
      expect(subject.cleanup).to eq(0)

      allow(Time).to receive(:now).and_return(time + 19)
      expect(subject.cleanup).to eq(1)
      expect(subject.read('foo')).to be_nil
      expect(subject.read('fud')).to eq('biz')
    end

    it 'should support namespace' do
      time = Time.now
      subject.write('foo', 'bar', expires_in: 10, namespace: 'x')
      subject.write('foo', 'biz', expires_in: 10, namespace: 'y')

      allow(Time).to receive(:now).and_return(time + 11)
      expect(subject.count).to eq(0)
      expect(subject.count(all: true)).to eq(2)

      expect(subject.cleanup(namespace: 'x')).to eq(1)
      expect(subject.count).to eq(0)
      expect(subject.count(all: true)).to eq(1)
    end
  end

  describe '#clear' do
    it 'should remove all entries' do
      subject.write('foo', 'bar')
      subject.write('fud', 'biz')
      expect(subject.clear).to be_truthy
      expect(subject.read('foo')).to be_nil
      expect(subject.read('fud')).to be_nil
    end

    it 'should support namespace' do
      subject.write('foo', 'bar', namespace: 'x')
      subject.write('foo', 'biz', namespace: 'y')
      expect(subject.count).to eq(2)

      expect(subject.clear(namespace: 'x')).to be_truthy
      expect(subject.count).to eq(1)
    end
  end

  describe '#fetch' do
    it 'should support cache hit' do
      subject.write('foo', 'bar')
      expect(subject).not_to receive(:write)

      expect(subject.fetch('foo') { 'baz' }).to eq('bar')
    end

    it 'should support cache miss' do
      expect(subject).to receive(:write).with('foo', 'baz', instance_of(Hash))
      expect(subject.fetch('foo') { 'baz' }).to eq('baz')
    end

    it 'should pass key to block on cache miss' do
      cache_miss = false
      expect(subject.fetch('foo') {|key| cache_miss = true; key.length }).to eq(3)
      expect(cache_miss).to be_truthy

      cache_miss = false
      expect(subject.fetch('foo') {|key| cache_miss = true; key.length }).to eq(3)
      expect(cache_miss).to be_falsey
    end

    it 'should support forced cache miss' do
      subject.write('foo', 'bar')
      expect(subject).not_to receive(:read)

      expect(subject.fetch('foo', force: true) { 'baz' }).to eq('baz')
    end

    it 'should support nil values' do
      subject.write('foo', nil)
      expect(subject).not_to receive(:write)

      expect(subject.fetch('foo') { 'baz' }).to be_nil
    end

    it 'should support skip_nil option' do
      expect(subject).not_to receive(:write)
      expect(subject.fetch('foo', skip_nil: true) { nil }).to be_nil
      expect(subject.exist?('foo')).to be_falsey
    end

    it 'should support forced cache miss with block' do
      subject.write('foo', 'bar')
      expect(subject.fetch('foo', force: true) { 'baz' }).to eq('baz')
    end

    it 'should support forced cache miss without block' do
      subject.write('foo', 'bar')
      expect { subject.fetch('foo', force: true) }.to raise_error(ArgumentError)
      expect(subject.read('foo')).to eq('bar')
    end
  end

  describe '#read_multi' do
    it 'should support read_multi' do
      subject.write('foo', 'bar')
      subject.write('fu', 'baz')
      subject.write('fud', 'biz')
      expect(subject.read_multi('foo', 'fu')).to eq('foo' => 'bar', 'fu' => 'baz')
    end

    it 'should support expires' do
      time = Time.now
      subject.write('foo', 'bar', expires_in: 10)
      subject.write('fu', 'baz')
      subject.write('fud', 'biz')

      allow(Time).to receive(:now).and_return(time + 11)
      expect(subject.read_multi('foo', 'fu')).to eq('fu' => 'baz')
    end
  end

  describe '#fetch_multi' do
    it 'should support fetch_multi' do
      subject.write('foo', 'bar')
      subject.write('fud', 'biz')
      values = subject.fetch_multi('foo', 'fu', 'fud') {|v| v * 2 }

      expect(values).to eq('foo' => 'bar', 'fu' => 'fufu', 'fud' => 'biz')
      expect(subject.read('fu')).to eq('fufu')
    end

    it 'should support without expires_in' do
      subject.write('foo', 'bar')
      subject.write('fud', 'biz')
      values = subject.fetch_multi('foo', 'fu', 'fud', expires_in: nil) {|v| v * 2 }

      expect(values).to eq('foo' => 'bar', 'fu' => 'fufu', 'fud' => 'biz')
      expect(subject.read('fu')).to eq('fufu')
    end

    it 'should support with objects' do
      cache_struct = Struct.new(:cache_key, :title)
      foo = cache_struct.new('foo', 'FOO!')
      bar = cache_struct.new('bar')

      subject.write('bar', 'BAM!')
      values = subject.fetch_multi(foo, bar, &:title)
      expect(values).to eq(foo => 'FOO!', bar => 'BAM!')
    end

    it 'should support ordered names' do
      subject.write('bam', 'BAM')
      values = subject.fetch_multi('foo', 'bar', 'bam', &:upcase)
      expect(values.keys).to eq(%w[foo bar bam])
    end

    it 'should raise without block' do
      expect { subject.fetch_multi('foo') }.to raise_error(ArgumentError)
    end
  end

  describe 'cache key' do
    it 'should support cache keys' do
      obj = Object.new
      def obj.cache_key
        :foo
      end
      subject.write(obj, 'bar')
      expect(subject.read('foo')).to eq('bar')
    end

    it 'should support to_param keys' do
      obj = Object.new
      def obj.to_param
        :foo
      end
      subject.write(obj, 'bar')
      expect(subject.read('foo')).to eq('bar')
    end

    it 'should support unversioned keys' do
      obj = Object.new
      def obj.cache_key
        :foo
      end

      def obj.cache_key_with_version
        'foo-v1'
      end
      subject.write(obj, 'bar')
      expect(subject.read('foo')).to eq('bar')
    end

    it 'should support array keys' do
      subject.write([:fu, 'foo'], 'bar')
      expect(subject.read('fu/foo')).to eq('bar')
    end

    it 'should support hash keys' do
      subject.write({ foo: 1, fu: 2 }, 'bar')
      expect(subject.read('foo=1/fu=2')).to eq('bar')
    end

    it 'should be case sensitive' do
      subject.write('foo', 'bar')
      expect(subject.read('FOO')).to be_nil
    end
  end

  describe 'with version' do
    it 'should support fetch/read' do
      subject.fetch('foo', version: 1) { 'bar' }
      expect(subject.read('foo', version: 1)).to eq('bar')
      expect(subject.read('foo', version: 2)).to be_nil
    end

    it 'should support write/read' do
      subject.write('foo', 'bar', version: 1)
      expect(subject.read('foo', version: 1)).to eq('bar')
      expect(subject.read('foo', version: 2)).to be_nil
    end

    it 'should support exists' do
      subject.write('foo', 'bar', version: 1)
      expect(subject.exist?('foo', version: 1)).to be_truthy
      expect(subject.exist?('foo', version: 2)).to be_falsey
    end

    it 'should cache/version keys' do
      m1v1 = ModelWithKeyAndVersion.new('model/1', 1)
      m1v2 = ModelWithKeyAndVersion.new('model/1', 2)

      subject.write(m1v1, 'bar')
      expect(subject.read(m1v1)).to eq('bar')
      expect(subject.read(m1v2)).to be_nil
    end

    it 'should normalise' do
      subject.write('foo', 'bar', version: 1)
      expect(subject.read('foo', version: '1')).to eq('bar')
    end
  end
end
