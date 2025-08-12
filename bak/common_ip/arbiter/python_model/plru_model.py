import numpy as np

class plru():
    def __init__(self,WD):
        self.WD = WD
        self.DP = int(np.log2(WD))
        self.matrix = np.zeros((WD,WD))
        self.node   = np.zeros(WD-1)

    def mapping(self, grant):
        for l in range(int(np.log2(self.WD))):
            for k in range(int(2**(np.log2(self.WD)-1-l))):
                for i in range(2**l):
                    for j in range(2**l):
                        self.matrix[i+k*2**(l+1)][j+2**l+k*2**(l+1)] = grant[int(2**(np.log2(self.WD)-1-l)+k-1)]

        for i in range(self.WD):
            for j in range(self.WD):
                if(i>j):
                    self.matrix[i][j] = 1 - self.matrix[j][i]
                elif(i==j):
                    self.matrix[i][j] = 0

        print(self.matrix)

    def update(self, alloc):
        for i in range(int(np.log2(self.WD))):
            for j in range(2**i):
                if(i==self.DP-1):
                    self.node[2**i+j-1] = (self.node[2**i+j-1] or alloc[2*j])*(1-alloc[2*j+1])

                    # print("level:%d node[%d] alloc_0[%d:%d] alloc_1[%d:%d]"% (i, 2**i+j-1, j*2**(self.DP-i-1), j*2**(self.DP-i-1)+2**(self.DP-i-2)-1, j*2**(self.DP-i-1)+2**(self.DP-i-2), \
                    #                                                           (j+1)*2**(self.DP-i-1)-1))
                else:
                    self.node[2**i+j-1] = (self.node[2**i+j-1] or np.any(alloc[j*2**(self.DP-i):j*2**(self.DP-i)+2**(self.DP-i-1)-1]))\
                                            *(1-np.any(alloc[j*2**(self.DP-i)+2**(self.DP-i-1):(j+1)*2**(self.DP-i)-1]))
                    
                    # print("level:%d node[%d] alloc_0[%d:%d] alloc_1[%d:%d]"% (i, 2**i+j-1, \
                    #                                                           j*2**(self.DP-i), j*2**(self.DP-i)+2**(self.DP-i-1)-1, \
                    #                                                           j*2**(self.DP-i)+2**(self.DP-i-1), (j+1)*2**(self.DP-i)-1))
        print(self.node)

    def gen_matrix(self, alloc):
        self.update(alloc)
        self.mapping(self.node)
    
    def init_matrix(self):
        self.mapping(self.node)


def main():
    # WD = 4
    # matrix = np.zeros((WD,WD))
    # grant = [1,1,0]
    # for l in range(int(np.log2(WD))):
    #     for k in range(int(2**(np.log2(WD)-1-l))):
    #         for i in range(2**l):
    #             for j in range(2**l):
    #                 matrix[i+k*2**(l+1)][j+2**l+k*2**(l+1)] = grant[int(2**(np.log2(WD)-1-l)+k-1)]

    # for i in range(WD):
    #     for j in range(WD):
    #         if(i>j):
    #             matrix[i][j] = 1 - matrix[j][i]
    #         elif(i==j):
    #             matrix[i][j] = 0

    # print(matrix)
    u = plru(8)
    u.init_matrix()
    u.gen_matrix([0,0,1,0,0,0,0,0])
    u.gen_matrix([1,0,0,0,0,0,0,0])


if __name__=="__main__":
    main()