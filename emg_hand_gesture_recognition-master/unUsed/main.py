# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.
import numpy as np
from PyQt5 import QtGui  # (the example applies equally well to PySide2)
import pyqtgraph as pg

def on_selectionChanged(selected, deselected):
    # global
    print(selected, deselected)
    # selected.indexes().row()
    for ix in selected.indexes():
        print(f'Selected cell location Row: {ix.row()} Column: {ix.column()}')

# Press the green button in the gutter to run the script.
if __name__ == '__main__':

    ## Always start by initializing Qt (only once per application)
    app = QtGui.QApplication([])

    ## Define a top-level widget to hold everything
    w = QtGui.QWidget()

    ## Create some widgets to be placed inside
    btn_start = QtGui.QPushButton('start')
    btn_stop = QtGui.QPushButton('stop')
    # text = QtGui.QLineEdit('enter text')
    table = QtGui.QTableWidget()
    table.setRowCount(10)
    table.setColumnCount(3)
    # table.setSelectionMode(QAbstractItemView.SingleSelection)
    table.selectionModel().selectionChanged.connect(on_selectionChanged)
    # table.setEditTriggers(QtGui.QAbstractItemView.NoEditTriggers)



    actions = ["idle", "fist", "flexion", "extension", "spread", "pinch index",\
               "pinch middle", "pinch ringer", "pinch little", "pinch all"]

    for j in range(3):
        idxRandom = np.random.choice(range(10), 10, replace=False)
        for i in range(10):
            table.setItem(i, j, QtGui.QTableWidgetItem(actions[idxRandom[i]]))

    # listw = QtGui.QListWidget()
    plot = pg.PlotWidget()
    imv = QtGui.QLabel()
    imv.setPixmap(QtGui.QPixmap("grey.jpeg"))


    ## Create a grid layout to manage the widgets size and position
    layout = QtGui.QGridLayout()
    w.setLayout(layout)

    ## Add widgets to the layout in their proper positions
    layout.addWidget(btn_start, 0, 0, 1, 1)  # button goes in upper-left
    layout.addWidget(btn_stop, 1, 0, 1, 1)  # text edit goes in middle-left
    layout.addWidget(table, 2, 0, 1, 2)  # list widget goes in bottom-left
    layout.addWidget(imv, 0, 2, 3, 1)
    layout.addWidget(plot, 0, 3, 3, 1)  # plot goes on right side, spanning 3 rows


    ## Display the widget as a new window
    w.show()

    ## Start the Qt event loop
    app.exec_()

