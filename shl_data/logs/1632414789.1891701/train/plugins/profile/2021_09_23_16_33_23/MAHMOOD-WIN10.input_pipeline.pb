	-@۪�s@-@۪�s@!-@۪�s@      ��!       "h
=type.googleapis.com/tensorflow.profiler.PerGenericStepDetails'-@۪�s@$%=�^2@1d��3�o@I�E�2}C@r0*	�~j�tW@2k
4Iterator::Root::ParallelMapV2::Zip[1]::ForeverRepeatͯ� ��?!��3=�>@)�$#gaO�?1������<@:Preprocessing2T
Iterator::Root::ParallelMapV2�	.V�`�?!'�:���;@)�	.V�`�?1'�:���;@:Preprocessing2u
>Iterator::Root::ParallelMapV2::Zip[0]::FlatMap[0]::Concatenateޯ|�y�?!�F9��4@)�f���?1n�n�uS'@:Preprocessing2E
Iterator::Root�4S�?!ڳ}�]\C@)
��ϛ��?1��Q�%@:Preprocessing2�
NIterator::Root::ParallelMapV2::Zip[0]::FlatMap[0]::Concatenate[0]::TensorSlice��iܛ߀?!����!@)��iܛ߀?1����!@:Preprocessing2Y
"Iterator::Root::ParallelMapV2::Zip�5[y���?!&L�,��N@)��ϛ�Tx?1ը�ʴ@:Preprocessing2e
.Iterator::Root::ParallelMapV2::Zip[0]::FlatMape��J�͖?!����8@)9��v��j?1\,k�3!@:Preprocessing2w
@Iterator::Root::ParallelMapV2::Zip[1]::ForeverRepeat::FromTensorK�8���\?!Fn�tw�?)K�8���\?1Fn�tw�?:Preprocessing:�
]Enqueuing data: you may want to combine small input data chunks into fewer but larger chunks.
�Data preprocessing: you may increase num_parallel_calls in <a href="https://www.tensorflow.org/api_docs/python/tf/data/Dataset#map" target="_blank">Dataset map()</a> or preprocess the data OFFLINE.
�Reading data from files in advance: you may tune parameters in the following tf.data API (<a href="https://www.tensorflow.org/api_docs/python/tf/data/Dataset#prefetch" target="_blank">prefetch size</a>, <a href="https://www.tensorflow.org/api_docs/python/tf/data/Dataset#interleave" target="_blank">interleave cycle_length</a>, <a href="https://www.tensorflow.org/api_docs/python/tf/data/TFRecordDataset#class_tfrecorddataset" target="_blank">reader buffer_size</a>)
�Reading data from files on demand: you should read data IN ADVANCE using the following tf.data API (<a href="https://www.tensorflow.org/api_docs/python/tf/data/Dataset#prefetch" target="_blank">prefetch</a>, <a href="https://www.tensorflow.org/api_docs/python/tf/data/Dataset#interleave" target="_blank">interleave</a>, <a href="https://www.tensorflow.org/api_docs/python/tf/data/TFRecordDataset#class_tfrecorddataset" target="_blank">reader buffer</a>)
�Other data reading or processing: you may consider using the <a href="https://www.tensorflow.org/programmers_guide/datasets" target="_blank">tf.data API</a> (if you are not using it now)�
:type.googleapis.com/tensorflow.profiler.BottleneckAnalysis�
both�Your program is POTENTIALLY input-bound because 5.9% of the total step time sampled is spent on 'All Others' time (which could be due to I/O or Python execution or both).moderate"�12.5 % of the total step time sampled is spent on 'Kernel Launch'. It could be due to CPU contention with tf.data. In this case, you may try to set the environment variable TF_GPU_THREAD_MODE=gpu_private.*noIP�8�^2@Qlޱ�BhT@Zno>Look at Section 3 for the breakdown of input time on the host.B�
@type.googleapis.com/tensorflow.profiler.GenericStepTimeBreakdown�
	$%=�^2@$%=�^2@!$%=�^2@      ��!       "	d��3�o@d��3�o@!d��3�o@*      ��!       2      ��!       :	�E�2}C@�E�2}C@!�E�2}C@B      ��!       J      ��!       R      ��!       Z      ��!       b      ��!       JGPUb qP�8�^2@ylޱ�BhT@