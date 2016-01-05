defmodule KV.BucketTest do
	use ExUnit.Case, async: true

	setup do
		{:ok, bucket} = KV.Bucket.start_link
		{:ok, bucket: bucket}
	end
	
	test "stores values by key", %{bucket: bucket} do
		assert KV.Bucket.get(bucket, "milk") == nil

		KV.Bucket.put(bucket, "milk", 3)
		assert KV.Bucket.get(bucket, "milk") == 3
	end

	test "deletes a key from bucket", %{bucket: bucket} do
		KV.Bucket.put(bucket, "joao", 15)
		KV.Bucket.delete(bucket, "joao")
		assert KV.Bucket.get(bucket, "joao") == nil
	end
	
end
