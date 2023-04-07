import numpy as np

class circlequeue:
    def __init__(self, _len, _dim):
        self.length = _len
        self.dimension = _dim
        self.data = np.zeros((_len, _dim))
        self.index_start = 0
        self.index_end = 0
        self.datasize = 0


    def add(self, new_data):
        self.data[self.index_end, :] = new_data
        self.index_end = (self.index_end + 1) % self.length
        if self.datasize < self.length:
            self.datasize = self.datasize + 1
        else:
            self.index_start = (self.index_start + 1) % self.length


    def addArray(self, new_data):
        nRowNew = new_data.shape[0]
        p_new_start = (self.index_end % self.length)
        p_new_end = p_new_start + nRowNew
        if p_new_end <= self.length:
            self.index_end = p_new_end
            self.data[p_new_start: p_new_end,:] = new_data
        else:
            nFirstPart = self.length - self.index_end
            nLeftPart = nRowNew - nFirstPart
            self.data[p_new_start: self.length,:] = new_data[: nFirstPart,:]
            self.data[: nLeftPart,:] = new_data[nFirstPart: nRowNew,:]
            self.index_end = p_new_end - self.length
        if self.datasize + nRowNew <= self.length:
            self.datasize = self.datasize + nRowNew
        else:
            self.datasize = self.length
            self.index_start = (self.index_end % self.length)


    def get(self, index, *args):
        if len(args) < 1:
            dim = np.arange(self.data.shape[1])
        else:
            dim = args[1]

        if index > self.length or index < 0:
            raise NotImplementedError

        return self.data[self.getOrignalIdx(index), dim]


    def getLast(self):
        return self.data[self.index_end-1,:]


    def getLastN(self, n):
        if self.datasize < n:
            idxStart = self.index_start
            idxEnd = self.index_end
        else:
            idxStart = self.getOrignalIdx(self.datasize - n)
            idxEnd = self.index_end

        if idxEnd > idxStart:
            d = self.data[idxStart:idxEnd,:]
        else:
            mid = self.length - idxStart
            d = np.zeros((n, self.dimension))
            d[: mid, :] = self.data[idxStart: self.length,:]
            d[mid: n, :] = self.data[:idxEnd, :]
        return d


    def get_fromEnd(self, index, *args):
        if len(args) < 1:
            dim = np.arange(self.data.shape[1])
        else:
            dim = args[1]

        if index >= self.length or index < 0:
            raise NotImplementedError
        idx = self.index_end-index
        if idx < 0:
            idx += self.length

        return self.data[idx, dim]
        # return self.get(self.index_end-index)
        # idx = self.getOrignalIdx(self.index_end-1-index)
        # # idx = self.getOrignalIdx(self.index_start + (self.datasize-index))
        # # idx = (self.index_end - index + 1 % self.length) + 1
        # d = self.data[idx, dim]
        #
        # return d


    def pop(self):
        if self.datasize == 0:
            return []
        d = self.data[self.index_end-1, :]
        self.index_end -= 1
        if self.index_end < 0:
            self.index_end += self.length
        self.datasize -= 1
        return d


    def pop_fromBeginning(self):
        if self.datasize == 0:
            return []
        d = self.data[self.index_start,:]
        self.index_start += 1
        if self.index_start >= self.length:
            self.index_start -= self.length

        # self.index_start = (self.index_start - 1 + 1 % self.length) + 1
        self.datasize = self.datasize - 1
        return d


    def getOrignalIdx(self, idxQueue):
        return (self.index_start + idxQueue) % self.length
        # idxArray = (self.index_start + idxQueue) % self.length
        # print(idxArray)
        # idxArray = self.index_start + idxQueue
        # if idxArray >= self.length:
        #     idxArray = idxArray - self.length
        # if idxArray >= self.length:
        #
        # print(idxArray)
        # return idxArray

    def set(self, range_start, range_end, value, *args):
        # range_start, range_end, value, dim
        # range_start, range_end, value = args[0], args[1], args[2]
        if len(args) < 1:
            dim = np.arange(self.data.shape[1])
        else:
            dim = args[0]
        idxStart = self.getOrignalIdx(range_start)
        idxEnd = self.getOrignalIdx(range_end)
        if idxEnd >= idxStart:
            self.data[idxStart: idxEnd, dim] = value
        else:
            # nTotalData = size(value, 1)
            nTotalData = value.shape[0]
            if nTotalData > 1:
                nFirstPart = self.length - idxStart
                self.data[idxStart: self.length, dim] = value[: nFirstPart,:]
                self.data[: idxEnd, dim] = value[nFirstPart: nTotalData,:]
            else:
                self.data[idxStart: self.length, dim] = value
                self.data[1: idxEnd, dim] = value

    def getArray(self, range_start, range_end, *args):

        if len(args) < 1:
            dim = np.arange(self.data.shape[1])
        else:
            dim = args[0]

        idxStart = self.getOrignalIdx(range_start)
        idxEnd = self.getOrignalIdx(range_end)

        if idxEnd >= idxStart:
            d = self.data[idxStart:idxEnd, dim]
        else:
            d1 = self.data[idxStart:self.length, dim]
            d2 = self.data[:idxEnd, dim]
            d = np.concatenate([d1, d2])
        return d

    def getArrayAll(self):
        return self.getLastN(self.datasize)